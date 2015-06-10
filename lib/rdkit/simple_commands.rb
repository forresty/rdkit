module RDKit
  module SimpleCommands
    def ping
      'PONG'
    end

    def echo(message)
      message
    end

    def time
      t = Time.now

      [t.to_i, t.usec].map(&:to_s)
    end
  end
end
