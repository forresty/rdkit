module Callbacks
  class Core < RDKit::Core
    def block
      server.blocking { do_something }
    end

    def nonblock
      do_something
    end

    def do_something
      sleep(rand)
    end

    def tick!
    end
  end
end
