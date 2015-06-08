# http://redis.io/commands/slowlog

module RDKit
  class SlowLog
    module ClassMethods
      @@logs = []
      @@sequence_id = 0

      def count
        @@logs.size
      end

      def reset
        @@logs.clear
      end

      def recent(count)
        if count == 0
          []
        elsif count > 0
          (@@logs[-count..-1] || @@logs).try(:reverse)
        else
          @@logs.try(:reverse)
        end
      end

      def monitor(cmd, &block)
        t0 = Time.now
        result = block.call
        elapsed_in_usec = ((Time.now - t0) * 1_000_000).to_i
        elapsed_in_milliseconds = elapsed_in_usec / 1_000

        if (threshold = Configuration.get_i('slowlog-log-slower-than')) >= 0
          if elapsed_in_milliseconds >= threshold
            @@logs << [@@sequence_id, Time.now.to_i, elapsed_in_milliseconds, cmd]
            @@sequence_id += 1

            if (max_len = Configuration.get_i('slowlog-max-len')) > 0
              @@logs = @@logs[-max_len..-1]
            end
          end
        end

        [result, elapsed_in_usec]
      end
    end

    class << self; include ClassMethods; end
  end
end
