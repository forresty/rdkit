module Counter
  class CommandRunner < RDKit::RESPRunner
    attr_reader :server

    def initialize(counter, server)
      @counter = counter
      @server  = server
    end

    # every public method of this class will be accessible by clients
    def count
      @counter.count
    end

    def incr(n=1)
      @counter.incr(n.to_i)
    end
  end
end
