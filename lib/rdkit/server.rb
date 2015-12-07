require "sigdump/setup"
require 'thread/pool'

module RDKit
  class Server
    HZ = 10

    HANDLED_SIGNALS = [ :TERM, :INT, :HUP ]

    attr_reader :server_up_since
    attr_reader :current_client
    attr_reader :current_db
    attr_reader :core
    attr_reader :host, :port
    attr_reader :logger
    attr_reader :monitors
    attr_reader :cycles
    attr_accessor :parser_class

    def responder
      @responder ||= (( @runner && $stderr.puts("@runner is deprecated, use @responder instead") ) || @runner)
    end

    def initialize(host, port)
      @host, @port = host, port

      @cycles = 0
      @peak_connected_clients = 0
      @client_id_seq = 0

      @clients = Hash.new
      @blocked_clients = Hash.new
      @monitors = []

      @logger = Logger.new(ENV['RDKIT_LOG_PATH'])
      @current_db = DB.new(0)
      @all_dbs = [@current_db]

      Introspection.register(self)

      @server_up_since = Time.now

      @parser_class = RESPParser

      register_notification_observers!

      Server.register(self)

      # Self-pipe for deferred signal-handling http://www.sitepoint.com/the-self-pipe-trick-explained/
      # Borrowed from `Foreman::Engine`
      reader, writer = create_pipe
      @selfpipe      = { :reader => reader, :writer => writer }
      @signal_queue  = []

      @additional_io_handlers = {}
    end

    def inject_io_handler(another_io, &block)
      @additional_io_handlers[another_io] = block
    end

    def start
      sanity_check!

      register_signal_handlers

      @server_socket = TCPServer.new(@host, @port)

      run_acceptor
    end

    def stop
      @logger.warn "shutting down..."
      exit
    end

    def create_pipe
      IO.method(:pipe).arity.zero? ? IO.pipe : IO.pipe("BINARY")
    end

    def register_signal_handlers
      HANDLED_SIGNALS.each do |sig|
        if ::Signal.list.include? sig.to_s
          trap(sig) { @signal_queue << sig ; notice_signal }
        end
      end
    end

    def notice_signal
      @selfpipe[:writer].write_nonblock('.')
    rescue Errno::EAGAIN
      # Ignore writes that would block
    rescue Errno::EINT
      # Retry if another signal arrived while writing
      retry
    end

    def handle_signals
      while sig = @signal_queue.shift
        handle_signal(sig)
      end
    end

    # Invoke the real handler for signal +sig+. This shouldn't be called directly
    # by signal handlers, as it might invoke code which isn't re-entrant.
    #
    # @param [Symbol] sig  the name of the signal to be handled
    #
    def handle_signal(sig)
      case sig
      when :TERM
        handle_term_signal
      when :INT
        handle_interrupt
      when :HUP
        handle_hangup
      else
        system "unhandled signal #{sig}"
      end
    end

    # Handle a TERM signal
    #
    def handle_term_signal
      @logger.warn "SIGTERM received"
      terminate_gracefully
    end

    # Handle an INT signal
    #
    def handle_interrupt
      @logger.warn "SIGINT received"
      terminate_gracefully
    end

    # Handle a HUP signal
    #
    def handle_hangup
      @logger.warn "SIGHUP received"
      terminate_gracefully
    end

    def terminate_gracefully
      return if @terminating

      @terminating = true

      stop
    end

    include MemoryMonitoring

    def introspection
      {
        server: {
          ruby_version: "#{RUBY_VERSION}p#{RUBY_PATCHLEVEL}",
          rdkit_version: RDKit::VERSION,
          multiplexing_api: 'select',
          process_id: Process.pid,
          tcp_port: @port,
          uptime_in_seconds: (Time.now - @server_up_since).to_i,
          uptime_in_days: ((Time.now - @server_up_since) / (24 * 60 * 60)).to_i,
          hz: HZ,
        },
        clients: {
          blocked_clients: @blocked_clients.size,
          connected_clients: @clients.size,
          connected_clients_peak: @peak_connected_clients
        },
        memory: {
          used_memory_rss: used_memory_rss_in_mb,
          used_memory_peak: used_memory_peak_in_mb
        },
      }
    end

    def delete(socket)
      @clients.delete(socket)
    end

    def clients
      @clients.values
    end

    def select_db!(index)
      if db = @all_dbs.find { |db| db.index == index }
        @current_db = db
      else
        @all_dbs << DB.new(index)

        @current_db = @all_dbs.last
      end
    end

    def flushdb!
      @current_db.flush!
    end

    def flushall!
      flushdb!

      @all_dbs = [@current_db]
    end

    def blocking(on_success=nil, &block)
      @blocked_clients[current_client.socket] = current_client
      @clients.delete(current_client.socket)

      current_client.blocking(on_success, &block)
    end

    def pool
      @pool ||= Thread.pool((ENV['RDKIT_SERVER_THREAD_POOL_SIZE'] || 10).to_i)
    end

    include Callbacks

    private

    def register_notification_observers!
      if webhook = ENV['RDKIT_SLOW_LOG_BEARYCHAT_WEBHOOK']
        require "httpi"
        require "multi_json"
        HTTPI.logger = Logger.new('/dev/null')

        NotificationCenter.subscribe('slowlog', self) do |cmd, usec|
          cmd, *args = cmd

          text = "host=#{@host} port=#{@port} cmd=#{cmd}(#{args.join(',') }) usec=#{usec}"

          pool.process { HTTPI.post(webhook, payload: MultiJson.dump({ text: text })) }
        end
      end
    end

    def sanity_check!
      unless @host && @port
        raise SDKRequirementNotMetError, '@host and @port are required for server to run'
      end

      if @core.nil?
        raise SDKRequirementNotMetError, '@core is required to represent your business logics'
      end

      if responder.nil?
        raise SDKRequirementNotMetError, '@responder is required to act as an RESP frontend'
      end

      if responder.server.nil?
        raise SDKRequirementNotMetError, '@responder should have reference to server'
      end
    end

    def add_client
      Introspection::Stats.incr(:total_connections_received)

      socket = @server_socket.accept_nonblock

      client = @clients[socket] = Client.new(socket, self)
      client.id = (@client_id_seq += 1)

      @logger.debug "client #{socket} connected"
      client_connected(client)

      update_peak_connected_clients!

      return @clients[socket]
    end

    def process(socket)
      client = @clients[socket]
      @current_client = client
      client.resume
      client_command_processed(client)
    rescue ClientDisconnectedError => e
      socket.close
      @monitors.delete(client)
      delete(socket)
      client_disconnected(client)
    end

    def run_acceptor
      @logger.info "accepting on shared socket (#{@host}:#{@port}), PID #{Process.pid}"

      server_started

      loop do
        process_blocked_clients
        process_clients

        @cycles += 1

        core.tick!

        gc_pool.process if @cycles % 1000 == 0
      end
    rescue Exception => e
      @logger.warn e unless e.class == SystemExit
      raise e
    end

    def gc_pool
      @gc_pool ||= Thread.pool(1) do
        _, usec = SlowLog.monitor('bg_gc') { GC.start }

        Introspection::Commandstats.record('bg_gc', usec)
      end
    end

    def process_blocked_clients
      @blocked_clients.each do |socket, client|
        if client.finished?
          @clients[socket] = client
          @blocked_clients.delete(socket)

          client.unblock!
        end
      end
    end

    def process_clients
      readable, _ = IO.select([@server_socket, @selfpipe[:reader], @clients.keys, @additional_io_handlers.keys].flatten, nil, nil, 1.0 / HZ)

      if readable
        readable.each do |socket|
          if socket == @server_socket
            add_client
          elsif socket == @selfpipe[:reader]
            handle_signals
          elsif block = @additional_io_handlers[socket]
            block.call
          else
            process(socket)
          end

          process_blocked_clients
        end
      end
    end

    def update_peak_connected_clients!
      @peak_connected_clients = [@peak_connected_clients, @clients.size].max
    end

    module ClassMethods
      def register(instance)
        @@instance = instance
      end

      def instance
        @@instance
      end
    end
    class << self; include ClassMethods; end
  end
end
