module RDKit
  class DB
    attr_reader :index

    def initialize(index=0)
      @index = index
    end
  end
end
