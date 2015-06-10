module RDKit
  class DB
    attr_reader :index

    def initialize(index=0)
      @index = index

      @objects = {}
    end

    def get(key)
      @objects[key]
    end

    def set(key, value)
      @objects[key] = value
    end
  end
end
