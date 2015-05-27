module RDKit
  class Core
    include Inheritable

    def tick!
      raise ShouldOverrideError
    end

    def introspection
      raise ShouldOverrideError
    end
  end
end
