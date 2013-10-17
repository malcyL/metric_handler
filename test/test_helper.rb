gem "minitest"
require "minitest/autorun"
require "minitest/pride"
require "minitest/mock"
require "minitest/stub_any_instance"
require "mocha/setup"

lib = File.expand_path('../../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "metric_handler"
