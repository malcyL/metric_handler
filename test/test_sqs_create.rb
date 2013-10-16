require_relative 'test_helper'

module MetricHandler
  class SqsCreateTest < Minitest::Test

    def test_create_sqs
      Configuration.instance.configure_from_file("config.yml")
      SqsCreator.create("test_queue")
    end

  end
end
