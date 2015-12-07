require 'socket'

module IOInject
  class Core < RDKit::Core
    def initialize(server)
      ############ injection starts here ############
      @injection_called = 0

      udp_socket = UDPSocket.new
      host, port = 'localhost', 8080
      udp_socket.bind(host, port)

      puts "UDP echo server injection code running at #{host}:#{port}"

      server.inject_io_handler(udp_socket) do
        begin
          msg, sender_addrinfo, _, *controls = udp_socket.recvmsg_nonblock

          p [msg, sender_addrinfo, _, *controls]

          # echo back
          udp_socket.send(msg, 0, sender_addrinfo)

          @injection_called += 1
        rescue IO::WaitReadable
          # simply pass
        end
      end
      ############ injection ends here ############
    end

    def tick!; end

    def introspection
      {
        ioinject_version: IOInject::VERSION,
        injection_called: @injection_called
      }
    end
  end
end
