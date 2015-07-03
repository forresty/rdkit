module Blocking
  class CommandRunner < RDKit::RESPRunner
    attr_reader :core

    def initialize(core)
      @core = core
    end

    def block_with_callback
      core.block_with_callback

      # this is ignored, instead `on_success` block of `core.block_with_callback` is evaluated and returned
      'OK'
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
