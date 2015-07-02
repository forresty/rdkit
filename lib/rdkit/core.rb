module RDKit
  class Core
    def tick!
      raise ShouldOverrideError
    end

    def server
      Server.instance
    end
  end
end
