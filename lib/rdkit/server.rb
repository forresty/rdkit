require "sigdump/setup"
require 'thread/pool'

module RDKit
  class Server
    HZ = 10

    attr_reader :server_up_since
    attr_reader :current_client
    attr_reader :current_db
    attr_reader :runner
    attr_reader :core
    attr_reader :host, :port
    attr_reader :logger
    attr_reader :monitors
    attr_reader :cycles

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

      Server.register(self)
    end

    def start
      sanity_check!

      @server_socket = TCPServer.new(@host, @port)

      run_acceptor
    end

    def stop
      @logger.warn "shutting down..."
      exit
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

    # callbacks
    def client_connected(client); end
    def client_disconnected(client); end
    def client_command_processed(client); end
    def client_block_resumed(client); end
    def client_blocked(client); end

    private

    def sanity_check!
      unless @host && @port
        raise SDKRequirementNotMetError, '@host and @port are required for server to run'
      end

      if @core.nil?
        raise SDKRequirementNotMetError, '@core is required to represent your business logics'
      end

      if @runner.nil?
        raise SDKRequirementNotMetError, '@runner is required to act as an RESP frontend'
      end

      if @runner.server.nil?
        raise SDKRequirementNotMetError, '@runner should have reference to server'
      end
    end

    def add_client
      Introspection::Stats.incr(:total_connections_received)

      socket = @server_socket.accept_nonblock

      client = @clients[socket] = Client.new(socket, self)
      client.id = (@client_id_seq += 1)

      @logger.debug "client #{socket} connected"
      client_connected(client)

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
      @logger.info "accepting on shared socket (#{@host}:#{@port})"

      loop do
        process_blocked_clients
        process_clients

        update_peak_connected_clients!

        @cycles += 1

        core.tick!

        gc_pool.process if @cycles % 1000 == 0
      end
    rescue Exception => e
      @logger.warn e
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
      readable, _ = IO.select([@server_socket, @clients.keys].flatten, nil, nil, 1.0 / HZ)

      if readable
        readable.each do |socket|
          if socket == @server_socket
            add_client
          else
            process(socket)
          end
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
