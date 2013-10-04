# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'metric_handler/version'

Gem::Specification.new do |spec|
  spec.name          = "metric_handler"
  spec.version       = MetricHandler::VERSION
  spec.authors       = ["MalcyL, mmmmmrob"]
  spec.email         = ["malcolm@landonsonline.me.uk, rob@dynamicorange.com"]
  spec.description   = %q{Metric Event Handler}
  spec.summary       = %q{Receives metric events from an SQS queue and posts current metrics to a HTTP endpoint.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
