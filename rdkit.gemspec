# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rdkit/version'

Gem::Specification.new do |spec|
  spec.name          = "rdkit"
  spec.version       = RDKit::VERSION
  spec.authors       = ["Forrest Ye"]
  spec.email         = ["afu@forresty.com"]

  spec.summary       = %q{RDKit is a simple toolkit to write Redis-like, single-threaded multiplexing-IO server.}
  spec.homepage      = "http://github.com/forresty/rdkit"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency 'hiredis'
  spec.add_runtime_dependency 'newrelic_rpm'
  spec.add_runtime_dependency 'sigdump'
  spec.add_runtime_dependency 'thread', '~> 0.2.1'
  spec.add_runtime_dependency 'http_parser.rb'
  spec.add_runtime_dependency 'rack'
  spec.add_runtime_dependency 'httpi'
  spec.add_runtime_dependency 'multi_json'

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 12.3"
  spec.add_development_dependency "rspec"
end
