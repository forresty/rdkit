module RDKit
  module Subcommands
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
        Introspection::Commandstats.reset

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
        server.clients.map do |client|
          client.info.map { |k, v| "#{k}=#{v}" }.join(' ')
        end.join("\n") + "\n"
      end

      def client_kill(*args)
        raise SyntaxError if args.size == 0

        if args.size == 1
          # client kill HOST:PORT
          if kill_by_addr(args.first)
            'OK'
          else
            raise NoSuchClientError
          end
        else
          raise SyntaxError if args.size % 2 != 0

          killed = 0
          while args.size > 0
            type, arg = args.shift.downcase, args.shift

            case type
            when 'id'
              id = arg.to_i

              if id.to_s != arg
                raise ValueNotAnIntegerOrOutOfRangeError
              end

              if client = server.clients.find { |client| client.id == id }
                killed += 1
                client.kill!
              end
            when 'addr'
              killed += 1 if kill_by_addr(arg)
            else
              raise SyntaxError
            end
          end

          killed
        end
      end

      def kill_by_addr(addr)
        if client = server.clients.find { |c| c.socket_addr == addr }
          client.kill!

          true
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

      def debug_segfault
        raise Exception, "simulating a crash..." # Exception is not StandardError
      end
    end
    include DebugSubcommands
  end
end
