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
    end
    include ServerCommands

    private

    def db
      server.current_db
    end
  end
end
