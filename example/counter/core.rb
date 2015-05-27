module Counter
  class Core < RDKit::Core
    attr_accessor :count

    def initialize
      @count = 0
      @last_tick = Time.now
    end

    def incr(n)
      @count += n
    end

    ###########################################
    # overriding required RDKit::Core methods
    ###########################################

    # `tick!` is called periodically by RDKit
    def tick!
      @last_tick = Time.now
    end

    def introspection
      {
        counter_version: Counter::VERSION,
        count: @count,
        last_tick: @last_tick
      }
    end
  end
end
