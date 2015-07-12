module RDKit
  class DB
    attr_reader :index

    def initialize(index=0)
      @index = index

      flush!
    end

    def flush!
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

      def getset(key, new_value)
        objects[key].try(:value).tap { set(key, new_value) }
      end

      def setnx(key, value)
        if objects[key]
          false
        else
          set(key, value)
          true
        end
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

      def type(key)
        objects[key].type.to_s rescue 'none'
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

      def lpop(key)
        if list = get_typed_object(key, :list)

          result = list.shift

          del([key]) if list.empty?

          result
        else
          nil
        end
      end

      def rpop(key)
        if list = get_typed_object(key, :list)

          result = list.pop

          del([key]) if list.empty?

          result
        else
          nil
        end
      end
    end
    include ListMethods

    module SetMethods
      def sadd(key, elements)
        if set = get_typed_object(key, :set)
          size0 = set.size

          elements.each { |e| set.add(e) }

          set.size - size0
        else
          objects[key] = RDObject.set(elements)

          objects[key].size
        end
      end

      def scard(key)
        if set = get_typed_object(key, :set)

          set.size
        else
          0
        end
      end

      def smembers(key)
        if set = get_typed_object(key, :set)

          set.to_a
        else
          []
        end
      end

      def sismember(key, value)
        if set = get_typed_object(key, :set)

          set.include?(value) ? 1 : 0
        else
          0
        end
      end

      def srem(key, elements)
        if set = get_typed_object(key, :set)
          size0 = set.size

          elements.each { |e| set.delete(e) }

          size0 - set.size
        else
          0
        end
      end
    end
    include SetMethods

    module HashMethods
      def hset(key, field, value)
        if hash = get_typed_object(key, :hash)
          existed = hash.has_key?(field) ? 0 : 1

          hash[field] = value

          existed
        else
          objects[key] = RDObject.create_hash(field, value)

          1
        end
      end

      def hget(key, field)
        if hash = get_typed_object(key, :hash)
          hash[field]
        end
      end

      def hexists?(key, field)
        if hash = get_typed_object(key, :hash)
          hash.has_key?(field)
        else
          false
        end
      end

      def hlen(key)
        if hash = get_typed_object(key, :hash)
          hash.size
        else
          0
        end
      end

      def hdel(key, fields)
        if hash = get_typed_object(key, :hash)
          size0 = hash.size

          fields.each { |f| hash.delete(f) }

          size0 - hash.size
        else
          0
        end
      end

      def hkeys(key)
        if hash = get_typed_object(key, :hash)
          hash.keys
        else
          []
        end
      end

      def hvals(key)
        if hash = get_typed_object(key, :hash)
          hash.values
        else
          []
        end
      end
    end
    include HashMethods

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
