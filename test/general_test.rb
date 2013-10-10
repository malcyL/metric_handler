require_relative 'test_helper'

module MetricHandler
  class GeneralTest < Minitest::Test
    def test_truth
      assert true
    end

    def test_it_creates
      handler = MetricHandler.new()
      refute handler.nil?
    end

    def test_it_runs
      #handler = MetricHandler.new()
      #output= handler.run
      #refute output.nil?
    end
  end
end
