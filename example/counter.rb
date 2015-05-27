require 'rdkit'

require_relative 'counter/version'
require_relative 'counter/core'
require_relative 'counter/command_runner'
require_relative 'counter/server'

server = Counter::Server.new

trap(:INT) { server.stop }

server.start
