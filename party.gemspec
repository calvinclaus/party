# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'party/version'

Gem::Specification.new do |spec|
  spec.name          = "consoleparty"
  spec.version       = Party::VERSION
  spec.authors       = ["Calvin Claus"]
  spec.email         = ["calvinclaus@me.com"]

  spec.summary       = %q{Makes your terminal party.}
  spec.homepage      = "https://github.com/calvinclaus/party"
  spec.license       = "MIT"


  spec.files         = ["lib/party.rb"]
  spec.executables   << 'party'

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.required_ruby_version = '>= 2.3.0'

  spec.add_runtime_dependency 'curses'
end
