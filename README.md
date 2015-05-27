# RDKit

RDKit is a simple toolkit to write Redis-like, single-threaded multiplexed-IO server.

The server speaks in [Redis RESP protocol](http://redis.io/topics/protocol), so you can reuse many Redis-compatible clients and tools such as:

- `redis-cli`
- `redis-benchmark`
- [redic](https://github.com/amakawa/redic)

And a lot more.

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

see example under `example` folder.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bin/console` for an interactive prompt that will allow you to experiment.

## Contributing

1. Fork it ( https://github.com/forresty/rdkit/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
