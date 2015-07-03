module Callbacks
  class CommandRunner < RDKit::RESPRunner
    attr_reader :core

    def initialize(core)
      @core = core
    end

    def block
      core.block

      'OK'
    end

    def nonblock
      core.nonblock

      'OK'
    end
  end
end
