# RDKit

RDKit is a simple toolkit to write Redis-like, single-threaded multiplexing-IO server.

The server speaks in [Redis RESP protocol](http://redis.io/topics/protocol), so you can reuse many Redis-compatible clients and tools such as:

- `redis-cli`
- `redis-benchmark`
- [Redic](https://github.com/amakawa/redic)

And a lot more.

`RDKit` is used to power the [520 Love Radio](http://s.weibo.com/weibo/same%2520%25E7%2594%25B5%25E5%258F%25B0) service of [same.com](http://same.com)

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

### Implementing a cycle-counter server

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
    end

    # `tick!` is called periodically by RDKit
    def tick!
      @count += 1
    end

    def introspection
      {
        counter_version: Counter::VERSION,
        count: @count
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
redis-cli -p 3721
127.0.0.1:3721> count
(integer) 12

127.0.0.1:3721> info
# Server
rdkit_version:0.0.1
multiplexing_api:select
process_id:12150
tcp_port:3721
uptime_in_seconds:8
uptime_in_days:0
hz:10

# Clients
connected_clients:1
connected_clients_peak:1

# Memory
used_memory_rss:27.66M
used_memory_peak:27.66M

# Counter
counter_version:0.0.1
count:24

# Stats
total_connections_received:1
total_commands_processed:1

127.0.0.1:3721> xx
(error) ERR unknown command 'xx'
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

1. Fork it ( https://github.com/forresty/rdkit/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
