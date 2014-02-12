# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'RestFullApi/version'

Gem::Specification.new do |spec|
  spec.name          = "RestFullApi"
  spec.version       = RestFullApi::VERSION
  spec.authors       = ["t0pep0"]
  spec.email         = ["t0pep0.gentoo@gmail.com"]
  spec.description   = "Write a gem description"
  spec.summary       = "Write a gem summary"
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "redcarpet"
  spec.add_development_dependency "yard"
  spec.add_development_dependency "rspec-expectations"
  spec.add_development_dependency "rspec-core"
  spec.add_development_dependency "rr"
  spec.add_dependency "rails"
end
