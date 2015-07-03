# 127.0.0.1:6379> info
# # Server
# redis_version:3.0.0
# redis_git_sha1:00000000
# redis_git_dirty:0
# redis_build_id:c8fc3cfae8617ea3
# redis_mode:standalone
# os:Darwin 14.3.0 x86_64
# arch_bits:64
# multiplexing_api:kqueue
# gcc_version:4.2.1
# process_id:6503
# run_id:42575aa7185796a6a5e5addc5991a54e4baaf95e
# tcp_port:6379
# uptime_in_seconds:165102
# uptime_in_days:1
# hz:10
# lru_clock:7932005
# config_file:/usr/local/etc/redis.conf
#
# # Clients
# connected_clients:1
# client_longest_output_list:0
# client_biggest_input_buf:0
# blocked_clients:0
#
# # Memory
# used_memory:1009568
# used_memory_human:985.91K
# used_memory_rss:1728512
# used_memory_peak:3486144
# used_memory_peak_human:3.32M
# used_memory_lua:35840
# mem_fragmentation_ratio:1.71
# mem_allocator:libc
#
# # Persistence
# loading:0
# rdb_changes_since_last_save:0
# rdb_bgsave_in_progress:0
# rdb_last_save_time:1433995353
# rdb_last_bgsave_status:ok
# rdb_last_bgsave_time_sec:0
# rdb_current_bgsave_time_sec:-1
# aof_enabled:0
# aof_rewrite_in_progress:0
# aof_rewrite_scheduled:0
# aof_last_rewrite_time_sec:-1
# aof_current_rewrite_time_sec:-1
# aof_last_bgrewrite_status:ok
# aof_last_write_status:ok
#
# # Stats
# total_connections_received:98
# total_commands_processed:265
# instantaneous_ops_per_sec:0
# total_net_input_bytes:273320
# total_net_output_bytes:1024738
# instantaneous_input_kbps:0.00
# instantaneous_output_kbps:0.00
# rejected_connections:0
# sync_full:0
# sync_partial_ok:0
# sync_partial_err:0
# expired_keys:0
# evicted_keys:0
# keyspace_hits:28
# keyspace_misses:11
# pubsub_channels:0
# pubsub_patterns:0
# latest_fork_usec:483
# migrate_cached_sockets:0
#
# # Replication
# role:master
# connected_slaves:0
# master_repl_offset:0
# repl_backlog_active:0
# repl_backlog_size:1048576
# repl_backlog_first_byte_offset:0
# repl_backlog_histlen:0
#
# # CPU
# used_cpu_sys:34.00
# used_cpu_user:13.61
# used_cpu_sys_children:0.05
# used_cpu_user_children:0.11
#
# # Cluster
# cluster_enabled:0
#
# # Keyspace
# db0:keys=3,expires=0,avg_ttl=0

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

    class Commandstats
      attr_reader :data

      def initialize
        @data = {}
        @data.default = 0
      end

      module ClassMethods
        @@instance = Commandstats.new

        def record(cmd, usec)
          @@instance.data["#{cmd.downcase}_calls"] += 1
          @@instance.data["#{cmd.downcase}_usec"] += usec
        end

        def info
          cmds = @@instance.data.keys.map { |key| key.match(/^(.+)_/)[1] }.uniq

          Hash[cmds.map do |cmd|
            calls = @@instance.data["#{cmd}_calls"]
            usec = @@instance.data["#{cmd}_usec"]

            ["comstat_#{cmd}", "calls=#{calls},usec=#{usec},usec_per_call=#{'%.2f' % (usec.to_f / calls)}"]
          end]
        end
      end

      class << self; include ClassMethods; end
    end

    module ClassMethods
      def register(server)
        @@server = server
      end

      def info(section)
        default = @@server.introspection.merge({ stats: Stats.info })

        case section.downcase
        when 'default'
          default
        when 'all'
          default.merge({ commandstats: Commandstats.info, gc: GC.stat, objspace: ObjectSpace.count_objects, allobjects: all_objects })
        when 'commandstats'
          { commandstats: Commandstats.info }
        else
          default.keep_if { |k, v| k == section.downcase.to_sym }
        end
      end

      private

      def all_objects
        all = {}
        ObjectSpace.each_object { |o| all[o.class] = (all[o.class] || 0) + 1 }
        all.sort_by {|k,v| -v }
      end
    end

    class << self; include ClassMethods; end
  end
end
