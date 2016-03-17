# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'alexa_hue/version'

Gem::Specification.new do |spec|
  spec.name          = "alexa_hue"
  spec.version       = Hue::VERSION
  spec.authors       = ["Kyle Lucas"]
  spec.email         = ["kglucas93@gmail.com"]
  spec.summary       = %q{A sinatra middleware for alexa hue actions.}
  spec.description   = %q{}
  spec.homepage      = "http://github.com/kylegrantlucas/alexa_hue"
  spec.license       = "MIT"
  spec.required_ruby_version = '>= 1.9.3'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib", 'skills_config']

  spec.add_runtime_dependency 'json'
  spec.add_runtime_dependency 'alexa_objects'
  spec.add_runtime_dependency 'httparty'
  spec.add_runtime_dependency 'numbers_in_words'
  spec.add_runtime_dependency 'activesupport'
  spec.add_runtime_dependency 'chronic'
  spec.add_runtime_dependency 'chronic_duration'
  spec.add_runtime_dependency 'takeout', '~> 1.0.6'
  spec.add_runtime_dependency 'sinatra-contrib'

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "webmock"

  spec.add_development_dependency "codeclimate-test-reporter"
end