# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'funkysystem/version'

Gem::Specification.new do |spec|
  spec.name          = "funkysystem"
  spec.version       = FunkySystem::VERSION
  spec.authors       = ["Geoff Youngs"]
  spec.email         = ["git@intersect-uk.co.uk"]
  spec.description   = %q{Like system() but with input feeding & output capture}
  spec.summary       = %q{Like system() but funkier}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
