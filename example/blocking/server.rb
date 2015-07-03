module Blocking
  class Server < RDKit::Server
    def initialize
      super('0.0.0.0', 3721)

      @core = Core.new
      @runner = CommandRunner.new(core)
    end
  end
end
