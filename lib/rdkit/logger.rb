module RDKit
  class Logger
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
        puts message.inspect
        puts message.backtrace.join("\n")
      else
        puts message
      end
    end
  end
end
