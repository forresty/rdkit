module RDKit
  class Core
    include Inheritable

    def tick!
      raise ShouldOverrideError
    end
  end
end
