require "hiredis/reader"
# http://redis.io/topics/protocol
# Hiredis::Reader does not handle inline commands, so

module RDKit
  class CommandParser
    def initialize
      @reader = Hiredis::Reader.new
      @buffer = []
      @regexp = Regexp.new("\\A(.+)\\r\\n\\z")
      @error  = nil
    end

    def feed(data)
      if data =~ @regexp
        @buffer << $1.split
      else
        @reader.feed(data)

        read_into_buffer!
      end
    end

    def gets
      raise @error unless @error.nil?

      if result = @buffer.shift

        result
      else
        @reader.gets
      end
    end

    private

    def read_into_buffer!
      until (reply = @reader.gets) == false
        @buffer << reply
      end
    rescue RuntimeError => e
      @error = ProtocolError.new(e) if e.message =~ /Protocol error/
    end
  end
end