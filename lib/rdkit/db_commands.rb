module RDKit
  module DBCommands
    def select(index)
      raise InvalidDBIndexError unless (0..15).map(&:to_s).include?(index)

      index = index.to_i

      server.select_db!(index)

      'OK'
    end

    module StringCommands
      def get(key)
        db.get(key)
      end

      def set(key, value)
        db.set(key, value)

        'OK'
      end

      def mget(key, *more_keys)
        ([key] + more_keys).map { |k| db.get(k) rescue nil }
      end

      def mset(key, value, *more_pairs)
        unless more_pairs.size % 2 == 0
          raise WrongNumberOfArgumentError, "wrong number of arguments for 'mset' command"
        end

        db.set(key, value)
        more_pairs.each_slice(2) { |key, value| db.set(key, value) }

        'OK'
      end

      def strlen(key)
        if str = db.get(key)
          str.bytesize
        else
          0
        end
      end
    end
    include StringCommands

    module ListCommands
      def lpush(key, value, *more_values)
        db.lpush(key, [value] + more_values)
      end

      def llen(key)
        db.llen(key)
      end

      def lrange(key, start, stop)
        db.lrange(key, start, stop)
      end
    end
    include ListCommands

    module SetCommands
      def sadd(key, value, *more_values)
        db.sadd(key, [value] + more_values)
      end

      def scard(key)
        db.scard(key)
      end

      def smembers(key)
        db.smembers(key)
      end

      def sismember(key, value)
        db.sismember(key, value)
      end

      def srem(key, value, *more_values)
        db.srem(key, [value] + more_values)
      end
    end
    include SetCommands

    module HashCommands
      def hset(key, field, value)
        db.hset(key, field, value)
      end
    end
    include HashCommands

    module KeyCommands
      def del(key, *more_keys)
        db.del(more_keys.unshift(key))
      end

      def keys(pattern)
        db.filter_keys(pattern)
      end

      def exists(key)
        db.exists?(key) ? 1 : 0
      end
    end
    include KeyCommands

    module ServerCommands
      def flushdb
        server.flushdb!

        'OK'
      end

      def flushall
        server.flushall!

        'OK'
      end
    end
    include ServerCommands

    private

    def db
      server.current_db
    end
  end
end
