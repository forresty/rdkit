module RDKit
  class Client
    attr_accessor :id
    attr_accessor :name
    attr_accessor :fd
    attr_accessor :last_command
    attr_reader   :socket

    def initialize(socket, server)
      @server = server
      @socket = socket
      @runner = server.runner
      @command_parser = CommandParser.new
      @logger = server.logger
      @created_at = Time.now
      @last_interacted_at = Time.now

      @fiber = Fiber.new do
        with_error_handling(socket) do |io|
          loop { process; Fiber.yield }
        end
      end
    end

    def resume
      @last_interacted_at = Time.now

      @fiber.resume
    end

    def info
      {
        id:   @id,
        addr: socket_addr,
        fd:   @socket.fileno,
        name: @name,
        age:  age,
        idle: idle,
        cmd:  @last_command
      }
    end

    def socket_addr
      @socket.remote_address.inspect_sockaddr
    end

    def name=(name)
      # http://www.asciitable.com
      # `networking.c` in redis source code
      name.each_char { |c| raise IllegalClientNameError unless c >= '!' && c <= '~' }

      @name = name
    end

    def kill!
      @socket.close
      @server.delete(@socket)
    end

    private

    def age
      (Time.now - @created_at).to_i
    end

    def idle
      (Time.now - @last_interacted_at).to_i
    end

    def with_error_handling(socket, &block)

      block.call(socket)

    rescue IOError, Errno::ECONNRESET, EOFError => e
      # client disconnected
      @logger.debug "client #{socket.inspect} has disconnected"
      @logger.debug e

      raise ClientDisconnectedError
    rescue ProtocolError => e
      # client protocol error, force disconnect
      @logger.debug "client protocol error"
      @logger.debug e
      socket.close

      raise ClientDisconnectedError
    end

    def process
      feed_parser

      until (reply = get_parser_reply) == false
        send_response(reply)
      end
    end

    def feed_parser
      cmd = @socket.readpartial(1024)

      Introspection::Stats.incr(:total_net_input_bytes, cmd.bytesize)

      @command_parser.feed(cmd)
    end

    def get_parser_reply
      @command_parser.gets
    end

    def send_response(cmd)
      @last_command = cmd.first

      @server.monitors.each do |client|
        msg = "+#{Time.now.to_f} [#{client.socket_addr}] #{ cmd.map { |c| %Q{"#{c}"}}.join(' ') }\r\n"

        client.socket.write(msg)
      end

      resp, usec = SlowLog.monitor(cmd) { @runner.resp(cmd) }

      Introspection::Commandstats.record(cmd.first, usec)
      Introspection::Stats.incr(:total_net_output_bytes, resp.bytesize)

      @logger.debug(resp)

      @socket.write(resp)
    end
  end
end
