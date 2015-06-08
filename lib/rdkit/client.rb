module RDKit
  class Client
    attr_accessor :id
    attr_accessor :name
    attr_accessor :fd
    attr_accessor :last_command

    def initialize(socket, server)
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
        addr: @socket.remote_address.inspect_sockaddr,
        fd:   @socket.fileno,
        name: @name,
        age:  age,
        idle: idle,
        cmd:  @last_command
      }
    end

    def name=(name)
      name.each_char do |c|
        # http://www.asciitable.com
        # `networking.c` in redis source code
        unless c >= '!' && c <= '~'
          raise IllegalArgumentError, "Client names cannot contain spaces, newlines or special characters."
        end
      end

      @name = name
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

    rescue Errno::ECONNRESET, EOFError => e
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

      resp, usec = SlowLog.monitor(cmd) { @runner.resp(cmd) }

      Introspection::Commandstats.record(cmd.first, usec)
      Introspection::Stats.incr(:total_net_output_bytes, resp.bytesize)

      @logger.debug(resp)

      @socket.write(resp)
    end
  end
end
