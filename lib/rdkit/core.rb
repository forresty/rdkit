module RDKit
  class Core
    def tick!
      raise ShouldOverrideError
    end
  end
end
