module RDKit
  class RESPRunner
    include Inheritable

    def resp(cmd)
      RESP.compose(call(cmd))
    rescue => e
      RESP.compose(e)
    end

    # 获取服务器状态
    def info(section=nil)
      info = if section.nil?
        Introspection.info
      else
        Introspection.info.keep_if { |k, v| k == section.downcase.to_sym }
      end

      unless info.empty?
        info.map do |type, value|
          "# #{type.capitalize}\r\n" + value.map { |k, v| "#{k}:#{v}" }.join("\r\n") + "\r\n"
        end.join("\r\n") + "\r\n"
      end
    end

    def echo(message)
      message
    end

    def config(cmd, *args)
      subcommands = %w{ resetstat }

      if subcommands.include?(cmd.downcase)
        __send__("config_#{cmd.downcase}", *args)
      else
        raise UnknownSubcommandError, "ERR CONFIG subcommand must be one of #{subcommands.map(&:upcase).join(', ')}"
      end
    end

    private

    def config_resetstat
      Introspection::Stats.clear(:total_commands_processed)
      Introspection::Stats.clear(:total_connections_received)
      Introspection::Stats.clear(:total_net_input_bytes)
      Introspection::Stats.clear(:total_net_output_bytes)

      'OK'
    end

    def call(cmd)
      @logger ||= Logger.new

      Introspection::Stats.incr(:total_commands_processed)

      @logger.debug "running command: #{cmd}"
      cmd, *args = cmd

      cmd.downcase!

      if self.respond_to?(cmd)
        self.__send__(cmd, *args)
      else
        raise UnknownCommandError, "ERR unknown command '#{cmd}'"
      end
    rescue ArgumentError => e
      raise WrongNumberOfArgumentError, "ERR wrong number of arguments for '#{cmd}' command"
    end

    module RedisCompatibility
      def select(id); 'OK'; end
      def ping; 'PONG'; end
    end

    include RedisCompatibility
  end
end
