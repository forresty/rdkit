# 127.0.0.1:6379> info
# # Server
# redis_version:2.8.17
# redis_git_sha1:00000000
# redis_git_dirty:0
# redis_build_id:32eb139b4f2b63
# redis_mode:standalone
# os:Darwin 13.4.0 x86_64
# arch_bits:64
# multiplexing_api:kqueue
# gcc_version:4.2.1
# process_id:471
# run_id:efa5b449cc3ba9c53f7bbb159a773e6ff20d575c
# tcp_port:6379
# uptime_in_seconds:1510124
# uptime_in_days:17
# hz:10
#
# # Clients
# connected_clients:1
# client_longest_output_list:0
# client_biggest_input_buf:0
#
# # Memory
# used_memory:124510288
# used_memory_human:118.74M
# used_memory_rss:119885824
# used_memory_peak:124510288
# used_memory_peak_human:118.74M
# used_memory_lua:33792
# mem_fragmentation_ratio:0.96
# mem_allocator:libc
#
# # Persistence
#
# # Stats
# total_connections_received:74408
# total_commands_processed:5122851
# instantaneous_ops_per_sec:0
# rejected_connections:0
# pubsub_channels:0
# pubsub_patterns:0

module RDKit
  module Introspection
    class Stats
      attr_reader :data

      def initialize
        @data = {}

        @data.default = 0
      end

      module ClassMethods
        @@instance = Stats.new

        def incr(key, amount=1)
          @@instance.data[key] += amount
        end

        def clear(key)
          @@instance.data[key] = 0
        end

        def info
          @@instance.data
        end
      end

      class << self; include ClassMethods; end
    end

    module ClassMethods
      def register(server)
        @@server = server
      end

      def info
        @@server.introspection.merge({ stats: Stats.info })
      end
    end

    class << self; include ClassMethods; end
  end
end
