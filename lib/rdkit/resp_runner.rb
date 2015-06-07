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

    def time
      t = Time.now

      [t.to_i, t.usec].map(&:to_s)
    end

    def config(cmd, *args)
      execute_subcommand('config', %w{ get set resetstat }, cmd, *args)
    end

    def slowlog(cmd, *args)
      execute_subcommand('slowlog', %w{ get reset len }, cmd, *args)
    end

    private

    def execute_subcommand(base, valid_subcommands, subcommand, *args)
      valid_subcommands, subcommand = valid_subcommands.map(&:upcase), subcommand.upcase

      if valid_subcommands.include?(subcommand)
        __send__("#{base}_#{subcommand.downcase}", *args)
      else
        raise UnknownSubcommandError, "ERR #{base.upcase} subcommand must be one of #{valid_subcommands.join(', ')}"
      end
    rescue ArgumentError => e
      raise WrongNumberOfArgumentForSubcommandError, "ERR Wrong number of arguments for #{base.upcase} #{subcommand.downcase}"
    end

    module SlowLogSubcommands
      private

      def slowlog_get(count=nil)
        if count
          if count.to_i.to_s != count
            raise IllegalArgumentError, 'ERR value is not an integer or out of range'
          end

          SlowLog.recent(count.to_i)
        else
          SlowLog.recent(-1)
        end
      end

      def slowlog_len
        SlowLog.count
      end

      def slowlog_reset
        SlowLog.reset

        'OK'
      end
    end
    include SlowLogSubcommands

    module ConfigSubcommands
      private

      def config_resetstat
        Introspection::Stats.clear(:total_commands_processed)
        Introspection::Stats.clear(:total_connections_received)
        Introspection::Stats.clear(:total_net_input_bytes)
        Introspection::Stats.clear(:total_net_output_bytes)

        'OK'
      end

      def config_get(key)
        if value = Configuration.get(key)
          [key, value]
        else
          []
        end
      end

      def config_set(key, value)
        Configuration.set(key, value)

        'OK'
      end
    end
    include ConfigSubcommands

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
