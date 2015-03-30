# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cf/deployer/version'

Gem::Specification.new do |spec|
  spec.name          = 'cf-deployer'
  spec.version       = CF::Deployer::VERSION
  spec.authors       = ['Benedict Dodd']
  spec.email         = ['ben.dodd@armakuni.com']
  spec.summary       = 'Deployment tooling for CF v2'
  spec.homepage      = 'https://github.com/armakuni/cf-deployer'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(/^spec\//)
  spec.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler',      '~> 1.6'
  spec.add_development_dependency 'rake',         '~> 10.3'
  spec.add_development_dependency 'rubocop',      '~> 0.29.1'
  spec.add_development_dependency 'rspec',        '~> 3.0.0'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rake'
  spec.add_development_dependency 'guard-rubocop'
  spec.add_development_dependency 'guard-bundler'
  spec.add_development_dependency 'growl'
  spec.add_development_dependency 'rb-inotify'
  spec.add_development_dependency 'rb-fsevent'
  spec.add_development_dependency 'rest_client'
  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'fakefs'
  spec.add_development_dependency 'webmock'
  spec.add_development_dependency 'thread_safe'

  spec.add_dependency 'retryable', '1.3.6'
  spec.add_dependency 'thor', '0.19.1'
end
