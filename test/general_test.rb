require_relative 'test_helper'

module MetricHandler
  class GeneralTest < Minitest::Test

    def test_it_creates
      handler = MetricHandler.new()
      refute handler.nil?
    end

    def test_it_runs
      skip 'This currently loops forever'
      handler = MetricHandler.new()
      output= handler.run
      refute output.nil?
    end
  end
end
