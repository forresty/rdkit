module RDKit
  class RESPRunner
    attr_reader :server

    def initialize(server)
      @server = server
    end

    def resp(cmd)
      RESP.compose(call(cmd))
    rescue => e
      RESP.compose(e)
    end

    include SimpleCommands
    include DBCommands

    # 获取服务器状态
    def info(section='default')
      info = Introspection.info(section)

      unless info.empty?
        info.map do |type, value|
          "# #{type.capitalize}\r\n" + value.map { |k, v| "#{k}:#{v}" }.join("\r\n") + "\r\n"
        end.join("\r\n") + "\r\n"
      end
    end

    def monitor
      server.monitors << server.current_client

      'OK'
    end

    def shutdown
      server.stop
    end

    include Subcommands
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
  end
end
