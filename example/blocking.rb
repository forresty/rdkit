require 'rdkit'

require_relative 'blocking/version'
require_relative 'blocking/core'
require_relative 'blocking/command_runner'
require_relative 'blocking/server'

server = Blocking::Server.new

trap(:INT) { server.stop }

server.start
