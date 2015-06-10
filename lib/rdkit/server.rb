module RDKit
  class Server
    HZ = 10
    CYCLES_TIL_MEMORY_RESAMPLE = 1000

    attr_reader :server_up_since
    attr_reader :current_client
    attr_reader :runner
    attr_reader :core
    attr_reader :host, :port
    attr_reader :logger
    attr_reader :monitors

    def initialize(host, port)
      @host, @port = host, port

      @cycles = 0
      @peak_connected_clients = 0
      @client_id_seq = 0

      @clients = Hash.new
      @monitors = []

      @logger = Logger.new

      Introspection.register(self)

      @server_up_since = Time.now
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

    def delete(socket)
      @clients.delete(socket)
    end

    def clients
      @clients.values
    end

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

      return @clients[socket]
    end

    def process(socket)
      client = @clients[socket]
      @current_client = client
      client.resume
    rescue ClientDisconnectedError => e
      @monitors.delete(client)
      delete(socket)
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
              process(socket)
            end
          end
        end

        update_peak_memory! if @cycles % CYCLES_TIL_MEMORY_RESAMPLE == 0
        update_peak_connected_clients!

        @cycles += 1

        core.tick!
      end
    end

    def update_peak_connected_clients!
      @peak_connected_clients = [@peak_connected_clients, @clients.size].max
    end
  end
end
