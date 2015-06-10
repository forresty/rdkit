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

    module KeyCommands
      def del(*keys)
        db.del(keys)
      end

      def keys(pattern)
        db.filter_keys(pattern)
      end
    end
    include KeyCommands

    private

    def db
      server.current_db
    end
  end
end
