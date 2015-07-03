module Callbacks
  class Server < RDKit::Server
    def initialize
      super('0.0.0.0', 3721)

      @core = Core.new
      @runner = CommandRunner.new(core)
    end

    def client_connected(client)
      puts "client_connected: #{client.id}"
    end

    def client_disconnected(client)
      puts "client_disconnected: #{client.id}"
    end

    def client_command_processed(client)
      puts "client_command_processed: #{client.id}"
    end

    def client_block_resumed(client)
      puts "client_block_resumed: #{client.id}"
    end

    def client_blocked(client)
      puts "client_blocked: #{client.id}"
    end
  end
end
