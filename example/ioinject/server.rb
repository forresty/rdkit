module IOInject
  class Server < RDKit::Server
    def initialize
      super('0.0.0.0', 3721)

      # @core is required by RDKit
      @core = Core.new(self)

      # @responder is also required by RDKit
      @responder = RESPResponder.new
    end

    def introspection
      super.merge(ioinject: @core.introspection)
    end
  end
end
