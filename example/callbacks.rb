require 'rdkit'

require_relative 'callbacks/core'
require_relative 'callbacks/command_runner'
require_relative 'callbacks/server'

server = Callbacks::Server.new

server.start
