module Counter
  class CommandRunner < RDKit::RESPRunner
    def initialize(counter)
      @counter = counter
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
