module RDKit
  class DB
    attr_reader :index

    def initialize(index=0)
      @index = index

      @objects = {}
    end

    module StringMethods
      def get(key)
        if object = get_typed_object(key, :string)
          object.value
        end
      end

      def set(key, value)
        objects[key] = RDObject.string(value)
      end
    end
    include StringMethods

    module KeyMethods
      def del(keys)
        keys.select { |key| objects.delete(key) }.count
      end

      def filter_keys(pattern)
        objects.keys
      end

      def exists?(key)
        objects.include?(key)
      end
    end
    include KeyMethods

    module ListMethods
      def lpush(key, elements)
        if list = get_typed_object(key, :list)
          list.unshift(*elements)

          list.length
        else
          # key not exist
          objects[key] = RDObject.list(elements)

          objects[key].length
        end
      end

      def llen(key)
        if list = get_typed_object(key, :list)

          list.length
        else
          0
        end
      end

      def lrange(key, start, stop)
        if list = get_typed_object(key, :list)

          list[start..stop]
        else
          []
        end
      end
    end
    include ListMethods

    private

    def objects
      @objects
    end

    def get_typed_object(key, type)
      if object = objects[key]
        raise WrongTypeError unless object.type == type

        object
      end
    end
  end
end
