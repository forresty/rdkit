module RDKit
  class RESPRunner
    include Inheritable

    def resp(cmd)
      RESP.compose(call(cmd))
    rescue => e
      RESP.compose(e)
    end

    # 获取服务器状态
    def info(section='default')
      info = Introspection.info(section)

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

    def monitor
      server.monitors << server.current_client

      'OK'
    end

    def shutdown
      server.stop
    end

    def config(cmd, *args)
      execute_subcommand('config', %w{ get set resetstat }, cmd, *args)
    end

    def slowlog(cmd, *args)
      execute_subcommand('slowlog', %w{ get reset len }, cmd, *args)
    end

    def client(cmd, *args)
      execute_subcommand('client', %w{ list kill getname setname }, cmd, *args)
    end

    def debug(cmd, *args)
      execute_subcommand('debug', %w{ sleep }, cmd, *args)
    end

    private

    def execute_subcommand(base, valid_subcommands, subcommand, *args)
      valid_subcommands, subcommand = valid_subcommands.map(&:upcase), subcommand.upcase

      if valid_subcommands.include?(subcommand)
        __send__("#{base}_#{subcommand.downcase}", *args)
      else
        raise UnknownSubcommandError, "#{base.upcase} subcommand must be one of #{valid_subcommands.join(', ')}"
      end
    rescue ArgumentError => e
      raise WrongNumberOfArgumentForSubcommandError, "Wrong number of arguments for #{base.upcase} #{subcommand.downcase}"
    end

    module SlowLogSubcommands
      private

      def slowlog_get(count=nil)
        if count
          if count.to_i.to_s != count
            raise ValueNotAnIntegerOrOutOfRangeError
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

    module ClientSubcommands
      private

      def client_getname
        server.current_client.name
      end

      def client_setname(name)
        server.current_client.name = name

        'OK'
      end

      def client_list
        server.clients.values.map do |client|
          client.info.map { |k, v| "#{k}=#{v}" }.join(' ')
        end.join("\n") + "\n"
      end

      def client_kill(*args)
        raise SyntaxError if args.size == 0

        if args.size == 1
          # client kill HOST:PORT
          addr = args.first

          if client = server.clients.values.find { |c| c.socket_addr == addr }
            require 'pry'
            binding.pry
            client.kill!

            'OK'
          else
            raise NoSuchClientError
          end
        else
          raise SyntaxError if args.size % 2 != 0

          killed = 0
          while args.size > 0
            type, id = args.shift.downcase, args.shift

            raise SyntaxError unless type == 'id'

            if id.to_i.to_s != id
              raise ValueNotAnIntegerOrOutOfRangeError
            end

            if client = server.clients.values.find { |client| client.id == id.to_i }
              killed += 1
              client.kill!
            end
          end

          killed
        end
      end
    end
    include ClientSubcommands

    module DebugSubcommands
      private

      def debug_sleep(sec)
        sleep sec.to_i

        'OK'
      end
    end
    include DebugSubcommands

    def call(cmd)
      @logger ||= Logger.new

      Introspection::Stats.incr(:total_commands_processed)

      @logger.debug "running command: #{cmd}"
      cmd, *args = cmd

      cmd.downcase!

      if self.respond_to?(cmd)
        self.__send__(cmd, *args)
      else
        raise UnknownCommandError, "unknown command '#{cmd}'"
      end
    rescue ArgumentError => e
      raise WrongNumberOfArgumentError, "wrong number of arguments for '#{cmd}' command"
    end

    module RedisCompatibility
      def select(id); 'OK'; end
      def ping; 'PONG'; end
    end

    include RedisCompatibility
  end
end
