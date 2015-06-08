require 'newrelic_rpm'

module RDKit
  class Server
    HZ = 10
    CYCLES_TIL_MEMORY_RESAMPLE = 1000

    attr_reader :server_up_since
    attr_reader :runner
    attr_reader :core
    attr_reader :host, :port

    def initialize(host, port)
      @host, @port = host, port

      @cycles = 0
      @peak_memory = 0
      @peak_connected_clients = 0

      @clients, @command_parsers = Hash.new, Hash.new

      @logger = Logger.new

      Introspection.register(self)

      @server_up_since = Time.now
    end

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

    def introspection
      {
        server: {
          rdkit_version: RDKit::VERSION,
          multiplexing_api: 'select',
          process_id: Process.pid,
          tcp_port: @port,
          uptime_in_seconds: (Time.now - @server_up_since).to_i,
          uptime_in_days: ((Time.now - @server_up_since) / (24 * 60 * 60)).to_i,
          hz: HZ,
        },
        clients: {
          connected_clients: @clients.size,
          connected_clients_peak: @peak_connected_clients
        },
        memory: {
          used_memory_rss: used_memory_rss_in_mb,
          used_memory_peak: used_memory_peak_in_mb
        },
      }
    end

    private

    def used_memory_rss_in_mb
      update_peak_memory!

      '%0.2f' % used_memory_rss + 'M'
    end

    def used_memory_peak_in_mb
      '%0.2f' % @peak_memory + 'M'
    end

    def add_client
      Introspection::Stats.incr(:total_connections_received)

      socket = @server_socket.accept_nonblock

      @command_parsers[socket] = CommandParser.new

      @clients[socket] = Fiber.new do
         with_error_handling(socket) do |io|
           loop { process(io); Fiber.yield }
         end
      end

      @logger.debug "client #{socket} connected"

      return @clients[socket]
    end

    def process(io)
      feed_parser(io)

      until (reply = get_parser_reply(io)) == false
        send_response(io, reply)
      end
    end

    def feed_parser(io)
      cmd = io.readpartial(1024)

      Introspection::Stats.incr(:total_net_input_bytes, cmd.bytesize)

      @command_parsers[io].feed(cmd)
    end

    def get_parser_reply(io)
      @command_parsers[io].gets
    end

    def send_response(io, cmd)
      resp, usec = SlowLog.monitor(cmd) { runner.resp(cmd) }

      Introspection::Commandstats.record(cmd.first, usec)
      Introspection::Stats.incr(:total_net_output_bytes, resp.bytesize)

      @logger.debug(resp)

      io.write(resp)
    end

    def with_error_handling(socket, &block)

      block.call(socket)

    rescue Errno::ECONNRESET, EOFError => e
      # client disconnected
      @logger.debug "client #{socket.inspect} has disconnected"
      @logger.debug e
      @command_parsers.delete(socket)
      @clients.delete(socket)
    rescue ProtocolError => e
      # client protocol error, force disconnect
      @logger.debug "client protocol error"
      @logger.debug e
      socket.close
      @command_parsers.delete(socket)
      @clients.delete(socket)
    end

    def run_acceptor
      @logger.info "accepting on shared socket (#{@host}:#{@port})"

      loop do
        readable, _ = IO.select([@server_socket, @clients.keys].flatten, nil, nil, 1.0 / HZ)

        if readable
          readable.each do |socket|
            if socket == @server_socket
              add_client
            else
              # client is a Fiber
              client = @clients[socket]
              client.resume
            end
          end
        end

        update_peak_memory! if @cycles % CYCLES_TIL_MEMORY_RESAMPLE == 0
        update_peak_connected_clients!

        @cycles += 1

        core.tick!
      end
    end

    def update_peak_memory!
      @peak_memory = [@peak_memory, used_memory_rss].max
    end

    def update_peak_connected_clients!
      @peak_connected_clients = [@peak_connected_clients, @clients.size].max
    end

    def used_memory_rss
      NewRelic::Agent::Samplers::MemorySampler.new.sampler.get_sample
    end
  end
end
