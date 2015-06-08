module RDKit
  class Client
    def initialize(socket, runner, logger)
      @socket = socket
      @runner = runner
      @command_parser = CommandParser.new
      @logger = logger

      @fiber = Fiber.new do
        with_error_handling(socket) do |io|
          loop { process; Fiber.yield }
        end
      end
    end

    def resume
      @fiber.resume
    end

    private

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
      resp, usec = SlowLog.monitor(cmd) { @runner.resp(cmd) }

      Introspection::Commandstats.record(cmd.first, usec)
      Introspection::Stats.incr(:total_net_output_bytes, resp.bytesize)

      @logger.debug(resp)

      @socket.write(resp)
    end
  end
end
