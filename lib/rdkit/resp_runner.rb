module RDKit
  class RESPRunner
    def run(cmd)
      RESP.compose(call(cmd))
    rescue StandardError => e
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

    def gc
      GC.start

      'OK'
    end

    def heapdump
      require "objspace"

      ObjectSpace.trace_object_allocations_start

      GC.start

      file = "tmp/heap-#{Process.pid}-#{Time.now.to_i}.json"

      ObjectSpace.dump_all(output: File.open(file, "w"))

      file
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
      execute_subcommand('debug', %w{ sleep segfault }, cmd, *args)
    end

    def server
      Server.instance
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
