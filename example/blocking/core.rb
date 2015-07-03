module Blocking
  class Core < RDKit::Core
    def block_with_callback
      on_success = lambda { 'success' }

      server.blocking(on_success) { do_something }
    end

    def block
      server.blocking { do_something }
    end

    def nonblock
      do_something
    end

    def do_something
      sleep 1
    end

    def tick!
    end
  end
end
