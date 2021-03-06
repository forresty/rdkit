module HTTP
  class Server < RDKit::Server
    def initialize
      super('0.0.0.0', 3721)

      # @core is required by RDKit
      @core = Core.new

      # @responder is also required by RDKit
      @responder = Responder.new

      @parser_class = RDKit::HTTPParser
    end

    def introspection
      super.merge(counter: @core.introspection)
    end
  end
end
