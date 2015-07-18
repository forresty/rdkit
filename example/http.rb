require 'rdkit'

require_relative 'http/core'
require_relative 'http/responder'
require_relative 'http/server'

server = HTTP::Server.new

server.start
