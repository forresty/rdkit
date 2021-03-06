# RDKit

`RDKit` is a simple toolkit to write Redis-like, single-threaded multiplexing-IO server.

The server speaks [Redis RESP protocol](http://redis.io/topics/protocol), so you can reuse many Redis-compatible clients and tools such as:

- `redis-cli`
- `redis-benchmark`
- [Redic](https://github.com/amakawa/redic)

And a lot more.

`RDKit` is used to power:

- [520 Love Radio](http://s.weibo.com/weibo/same%2520%25E7%2594%25B5%25E5%258F%25B0) service of [same.com](http://same.com)
- AntiSpam blacklisted photo filtering service used at [same.com](http://same.com) (BK-Tree + pHash)
- channel unread count service at [same.com](http://same.com)

[![Code Climate](https://codeclimate.com/github/forresty/rdkit/badges/gpa.svg)](https://codeclimate.com/github/forresty/rdkit)
[![Build Status](https://travis-ci.org/forresty/rdkit.svg?branch=master)](https://travis-ci.org/forresty/rdkit)

`RDKit` should work without problem on `MRI` 2.2+, may encounter bugs on earlier version of `MRI` or `JRuby` or `Rubinus`, in that case, please kindly open an issue on GitHub

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

Generally, you should implement one subclass for each of the 3 classes: `RDKit::RESPResponder`, `RDKit::Core` and `RDKit::Server`, and spawn one object for each class.

Your server object should have two instance variables `@responder` and `@core` pointed to your spawned instances.

### RDKit::Server

```ruby
class YourServer < RDKit::Server
  def initialize
    super('0.0.0.0', 3721)

    @core = YourCore.new
    @responder = YourResponder.new(core)
  end
end

server = YourServer.new

trap(:INT) { server.stop }

server.start
```

This will start a `TCPServer` on `0.0.0.0:3721` and stops when you `CTRL-C`.

### RDKit::RESPResponder

`@responder` maps Redis commands to its methods and arguments, for example `info` will be sent to `RESPResponder#info`, and `info all` to `RESPResponder#info` with `"all"` as its first argument.

The return ruby object of each method will be marshaled as RESP strings, for example `'OK'` becomes `"+OK\r\n"`.

For example, with following implementation in your `RESPResponder` subclass:

```ruby
def add(a, b)
  a.to_i + b.to_i
end
```

You implemented an adder using RDKit! See it in action:

```shell
$ redis-cli -p 3721
127.0.0.1:3721> add 1 2
(integer) 3
127.0.0.1:3721> add 5
(error) ERR wrong number of arguments for 'add' command
127.0.0.1:3721>
```

The detailed algorithm can be found in `resp.rb`, at the time of writing it is like this:

```ruby
def compose(data)
  case data
  when *%w{ OK string list set hash zset none }
    "+#{data}\r\n"
  when true
    ":1\r\n"
  when false
    ":0\r\n"
  when Integer
    ":#{data}\r\n"
  when Array
    "*#{data.size}\r\n" + data.map { |i| compose(i) }.join
  when NilClass
    # Null Bulk String, not Null Array of "*-1\r\n"
    "$-1\r\n"
  when WrongTypeError
    "-WRONGTYPE #{data.message}\r\n"
  when StandardError
    "-ERR #{data.message}\r\n"
  else
    # always Bulk String
    "$#{data.bytesize}\r\n#{data}\r\n"
  end
end
```

### RDKit::Core

You are required to implement a `tick!` method. `RDKit` will call it periodically (currently roughly every 0.1 sec), this gives you a chance to do some house-keeping. For example:

```ruby
def tick!
  save_non_critical_data! if server.cycles % 1000 == 0
end
```

### Examples

See examples under `example` folder.

#### Implementing a counter server

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

#### Connect using `redis-cli`

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

Hint: if you are adventurous, try `info all`

#### Benchmarking with `redis-benchmark`

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

#### Implementing blocked commands

Some commands will be blocking: they may either depend on external services or need some background tasks to be run.

The clients will expect those commands to be blocking calls, they will not return until the commands are finished, but we don't want the server to be blocked as well.

Therefore we introduce `Server#blocking` methods, execution wrapped in this method call will be run in a background thread pool, and the client will be on hold until that task is finished.

Example: see `examples/blocking` folder.

```ruby
# blocking/command_runner.rb

module Blocking
  class CommandRunner < RDKit::RESPRunner
    attr_reader :core

    def initialize(core)
      @core = core
    end

    def block_with_callback
      core.block_with_callback

      # this is ignored, instead `on_success` block of `core.block_with_callback` is evaluated and returned
      'OK'
    end

    def block
      core.block

      'OK'
    end

    def nonblock
      core.nonblock

      'OK'
    end
  end
end

# blocking/core.rb

module Blocking
  class Core < RDKit::Core
    def block_with_callback
      on_success = lambda { 'success' }

      server.blocking(on_success) { do_something }
    end

    def block
      server.blocking { do_something }
    end

    def nonblock
      do_something
    end

    def do_something
      sleep 1
    end

    def tick!
    end
  end
end
```

Running:

```shell
$ redis-cli -p 3721
127.0.0.1:3721> block
OK
(1.03s)
127.0.0.1:3721> nonblock
OK
(1.01s)
127.0.0.1:3721> block_with_callback
"success"
(1.02s)
```

Benchmarking:

```shell
$ redis-benchmark -p 3721 -n 10 block
====== block ======
  10 requests completed in 1.03 seconds
  50 parallel clients
  3 bytes payload
  keep alive: 1

10.00% <= 1027 milliseconds
100.00% <= 1027 milliseconds
9.73 requests per second

$ redis-benchmark -p 3721 -n 10 nonblock
====== nonblock ======
  10 requests completed in 10.04 seconds
  50 parallel clients
  3 bytes payload
  keep alive: 1

10.00% <= 1001 milliseconds
20.00% <= 2005 milliseconds
30.00% <= 3010 milliseconds
40.00% <= 4013 milliseconds
50.00% <= 5018 milliseconds
60.00% <= 6022 milliseconds
70.00% <= 7027 milliseconds
80.00% <= 8030 milliseconds
90.00% <= 9034 milliseconds
100.00% <= 10039 milliseconds
1.00 requests per second

```

See the difference between blocking and non-blocking commands?

#### Additional IO Handler Injection

Since RDKit version 0.1.5, it allows injection of additional IO handlers into the main loop.

For examples, please refer to `examples/ioinject` for an injected UDP echo server.

### Implemented Redis Commands

| command     | support                              | note                                         |
|-------------|--------------------------------------|----------------------------------------------|
| `info`      | full                                 | additional `objspace` and `gc` commands      |
| `ping`      | full                                 |                                              |
| `echo`      | full                                 |                                              |
| `time`      | full                                 |                                              |
| `select`    | partial/compatible                   | `redis-benchmark` requires `select` command  |
| `config`    | `get`, `set`, `resetstat`            |                                              |
| `slowlog`   | full                                 |                                              |
| `client`    | `getname`, `setname`, `list`, `kill` | `kill` filter only supports `id`, `addr`     |
| `monitor`   | full                                 |                                              |
| `debug`     | `sleep`, `segfault`                  |                                              |
| `shutdown`  | full                                 |                                              |
| `get`       | full                                 |                                              |
| `set`       | without options                      |                                              |
| `del`       | full                                 |                                              |
| `keys`      | without pattern (return all)         |                                              |
| `lpush`     | full                                 |                                              |
| `lpop`      | full                                 |                                              |
| `rpop`      | full                                 |                                              |
| `llen`      | full                                 |                                              |
| `lrange`    | partial (not fully tested)           |                                              |
| `exists`    | full                                 |                                              |
| `flushdb`   | full                                 |                                              |
| `flushall`  | full                                 |                                              |
| `mget`      | full                                 |                                              |
| `mset`      | full                                 |                                              |
| `strlen`    | full                                 |                                              |
| `sadd`      | full                                 |                                              |
| `scard`     | full                                 |                                              |
| `smembers`  | full                                 |                                              |
| `sismember` | full                                 |                                              |
| `srem`      | full                                 |                                              |
| `hset`      | full                                 |                                              |
| `hget`      | full                                 |                                              |
| `hexists`   | full                                 |                                              |
| `hlen`      | full                                 |                                              |
| `hstrlen`   | full                                 |                                              |
| `hdel`      | full                                 |                                              |
| `hkeys`     | full                                 |                                              |
| `hvals`     | full                                 |                                              |
| `setnx`     | full                                 |                                              |
| `getset`    | full                                 |                                              |


### Implemented Additional Commands

| command     | description                                                                |
|-------------|----------------------------------------------------------------------------|
| `gc`        | start garbage collection immediately                                       |
| `heapdump`  | `ObjectSpace.dump_all` to ./tmp                                            |


## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

1. Fork it ( https://github.com/forresty/rdkit/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
