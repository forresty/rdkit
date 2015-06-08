module Counter
  class Server < RDKit::Server
    def initialize
      super('0.0.0.0', 3721)

      # @core is required by RDKit
      @core = Core.new

      # @runner is also required by RDKit
      @runner = CommandRunner.new(@core, self)
    end

    def introspection
      super.merge(counter: @core.introspection)
    end
  end
end
