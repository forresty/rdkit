require "hiredis/reader"
# http://redis.io/topics/protocol
# Hiredis::Reader does not handle inline commands, so

module RDKit
  class RESPParser
    def initialize
      @reader = Hiredis::Reader.new
      @buffer = []
      @regexp = Regexp.new("\\A(.+)\\r\\n\\z")
      @inline_mode = true
    end

    def feed(data)
      if @inline_mode && (data =~ @regexp)
        @buffer << $1.split
      else
        @inline_mode = false

        @reader.feed(data)
      end
    end

    def gets
      if @inline_mode && (result = @buffer.shift)

        result
      else
        @reader.gets
      end
    end
  end
end
