module HTTP
  class Core < RDKit::Core
    def initialize
      @last_tick = Time.now
    end

    # `tick!` is called periodically by RDKit
    def tick!
      @last_tick = Time.now
    end

    def introspection
      {
        last_tick: @last_tick
      }
    end
  end
end
