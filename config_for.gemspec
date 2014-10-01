# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'config_for/version'

Gem::Specification.new do |spec|
  spec.name          = 'config_for'
  spec.version       = ConfigFor::VERSION
  spec.authors       = ['Michal Cichra']
  spec.email         = ['michal@3scale.net']
  spec.summary       = %q{Provides YAML tools for app configuration.}
  spec.description   = %q{Simplifies YAML parsing in Sinatra and Rails applications. Provides tools to generate configs by capistrano.}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z 2> /dev/null`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'

  spec.add_development_dependency 'rspec', '~> 3.1'
end
