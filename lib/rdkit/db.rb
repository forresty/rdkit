module RDKit
  class DB
    attr_reader :index

    def initialize(index=0)
      @index = index

      @objects = {}
    end

    def get(key)
      if object = @objects[key]
        raise WrongTypeError unless object.type == :string

        object.value
      end
    end

    def set(key, value)
      @objects[key] = RDObject.string(value)
    end

    def del(keys)
      keys.select { |key| @objects.delete(key) }.count
    end

    def filter_keys(pattern)
      @objects.keys
    end

    def lpush(key, elements)
      if list = @objects[key]
        raise WrongTypeError unless list.type == :list

        list.unshift(*elements)

        list.length
      else
        # key not exist
        @objects[key] = RDObject.list(elements)

        @objects[key].length
      end
    end

    def llen(key)
      if list = @objects[key]
        raise WrongTypeError unless list.type == :list

        list.length
      else
        0
      end
    end
  end
end
