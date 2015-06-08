# http://redis.io/topics/protocol

module RDKit
  class RESP
    module ClassMethods
      def compose(data)
        case data
        when 'OK'
          # Bulk String "OK" will be displayed by redis-cli as "OK"
          # While Simple String "OK" will be displayed as non-quoted OK
          "+OK\r\n"
        when Integer
          ":#{data}\r\n"
        when Array
          "*#{data.size}\r\n" + data.map { |i| compose(i) }.join
        when NilClass
          # Null Bulk String, not Null Array of "*-1\r\n"
          "$-1\r\n"
        when StandardError
          "-ERR #{data.message}\r\n"
        else
          # always Bulk String
          "$#{data.bytesize}\r\n#{data}\r\n"
        end
      end
    end

    class << self; include ClassMethods; end
  end
end
