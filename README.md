# RDKit

RDKit is a simple toolkit to write Redis-like, single-threaded multiplexing-IO server.

The server speaks [Redis RESP protocol](http://redis.io/topics/protocol), so you can reuse many Redis-compatible clients and tools such as:

- `redis-cli`
- `redis-benchmark`
- [Redic](https://github.com/amakawa/redic)

And a lot more.

`RDKit` is used to power the [520 Love Radio](http://s.weibo.com/weibo/same%2520%25E7%2594%25B5%25E5%258F%25B0) service of [same.com](http://same.com)

[![Code Climate](https://codeclimate.com/github/forresty/rdkit/badges/gpa.svg)](https://codeclimate.com/github/forresty/rdkit)
[![Build Status](https://travis-ci.org/forresty/rdkit.svg?branch=master)](https://travis-ci.org/forresty/rdkit)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rdkit'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rdkit

## Usage

see examples under `example` folder.

### Implementing a counter server

A simple counter server source code listing:

```ruby
require 'rdkit'

# counter/version.rb
module Counter
  VERSION = '0.0.1'
end

# counter/core.rb
module Counter
  class Core < RDKit::Core
    attr_accessor :count

    def initialize
      @count = 0
      @last_tick = Time.now
    end

    # `tick!` is called periodically by RDKit
    def tick!
      @last_tick = Time.now
    end

    def incr(n)
      @count += n
    end

    def introspection
      {
        counter_version: Counter::VERSION,
        count: @count,
        last_tick: @last_tick
      }
    end
  end
end

# counter/command_runner.rb
module Counter
  class CommandRunner < RDKit::RESPRunner
    def initialize(counter)
      @counter = counter
    end

    # every public method of this class will be accessible by clients
    def count
      @counter.count
    end

    def incr(n=1)
      @counter.incr(n.to_i)
    end
  end
end

# counter/server.rb
module Counter
  class Server < RDKit::Server
    def initialize
      super('0.0.0.0', 3721)

      # @core is required by RDKit
      @core = Core.new

      # @runner is also required by RDKit
      @runner = CommandRunner.new(@core)
    end

    def introspection
      super.merge(counter: @core.introspection)
    end
  end
end

# start server

server = Counter::Server.new

trap(:INT) { server.stop }

server.start

```

### Connect using `redis-cli`

```shell
$ redis-cli -p 3721
127.0.0.1:3721> count
(integer) 0
127.0.0.1:3721> incr
(integer) 1
127.0.0.1:3721> incr 10
(integer) 11
127.0.0.1:3721> count
(integer) 11
127.0.0.1:3721> info
# Server
rdkit_version:0.0.1
multiplexing_api:select
process_id:15083
tcp_port:3721
uptime_in_seconds:268
uptime_in_days:0
hz:10

# Clients
connected_clients:1
connected_clients_peak:1

# Memory
used_memory_rss:31.89M
used_memory_peak:31.89M

# Counter
counter_version:0.0.1
count:11
last_tick:2015-05-27 20:15:38 +0800

# Stats
total_connections_received:1
total_commands_processed:6

127.0.0.1:3721> xx
(error) ERR unknown command 'xx'
```

### Benchmarking with `redis-benchmark`

```shell
$ redis-benchmark -p 3721 incr
====== count ======
  10000 requests completed in 0.73 seconds
  50 parallel clients
  3 bytes payload
  keep alive: 1

0.01% <= 1 milliseconds
2.27% <= 2 milliseconds
42.31% <= 3 milliseconds
63.99% <= 4 milliseconds
96.14% <= 5 milliseconds
...
99.97% <= 68 milliseconds
99.98% <= 71 milliseconds
99.99% <= 74 milliseconds
100.00% <= 77 milliseconds
13679.89 requests per second
```

Since it is single-threaded, the count will be correct:

```shell
127.0.0.1:3721> count
(integer) 10000
```

### Implemented Redis Commands

| command   | support                   | note                                        |
|-----------|---------------------------|---------------------------------------------|
| `info`    | full                      |                                             |
| `ping`    | full                      |                                             |
| `echo`    | full                      |                                             |
| `select`  | partial/compatible        | `redis-benchmark` requires `select` command |
| `config`  | `get`, `set`, `resetstat` |                                             |

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

1. Fork it ( https://github.com/forresty/rdkit/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
