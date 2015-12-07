require 'rdkit'

require_relative 'ioinject/version'
require_relative 'ioinject/core'
require_relative 'ioinject/resp_responder'
require_relative 'ioinject/server'

server = IOInject::Server.new

server.start
