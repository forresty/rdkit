module Counter
  class Core < RDKit::Core
    attr_accessor :count

    def initialize
      @count = 0
    end
    ###########################################
    # overriding required RDKit::Core methods
    ###########################################

    # `tick!` is called periodically by RDKit
    def tick!
      @count += 1
    end

    def introspection
      {
        counter_version: Counter::VERSION,
        count: @count
      }
    end
  end
end
