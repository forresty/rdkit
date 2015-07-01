module RDKit
  class Logger
    def initialize(log_path=nil)
      @io = log_path ? File.open(log_path, 'a') : $stdout
    end

    def debug(message)
      return unless $DEBUG && ENV['RACK_ENV'] != 'test'

      log(message)
    end

    def info(message)
      log(message)
    end

    def warn(message)
      log(message)
    end

    def log(message)
      case message
      when StandardError
        @io.puts message.inspect
        @io.puts message.backtrace.join("\n")
      else
        @io.puts message
      end
      @io.flush
    end
  end
end
