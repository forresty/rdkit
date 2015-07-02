module Blocking
  class CommandRunner < RDKit::RESPRunner
    attr_reader :core

    def initialize(core)
      @core = core
    end

    def block
      core.block
    end
  end
end
