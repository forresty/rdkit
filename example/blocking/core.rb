module Blocking
  class Core < RDKit::Core
    def block
      server.blocking do
        sleep 1
        'hoho'
      end
    end

    def tick!
    end
  end
end
