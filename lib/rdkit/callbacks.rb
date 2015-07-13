module RDKit
  module Callbacks
    def server_started; end
    def client_connected(client); end
    def client_disconnected(client); end
    def client_command_processed(client); end
    def client_block_resumed(client); end
    def client_blocked(client); end
  end
end
