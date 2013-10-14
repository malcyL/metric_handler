require_relative 'test_helper'

module MetricHandler
  class SnsPublisherTest < Minitest::Test

    def setup
      MetricHandler.configure_from_file 'test/test_config.yml'
      @topic = "test_topic"
      @message = "test message"
      @arn = "test_arn"
    end

    def setup_publisher( options = {} )
      @message = options.fetch(:message, @message)
      @topic = options.fetch(:topic, @topic)
      @publisher = SnsPublisher.new(@message, @topic)
    end

    def setup_sns(sns = nil)
      Fog::AWS::SNS.expects(:new)
        .with(:aws_access_key_id     => 'test-aws-access-key',
              :aws_secret_access_key => 'test-aws-secret-key',
              :region                => 'test-aws-region')
        .returns(sns)
    end

    def test_it_creates
      setup_publisher
      refute @publisher.nil?
    end

    def test_it_does_nothing_if_topic_nil
      sns = mock()
      setup_sns(sns)

      setup_publisher(topic: nil)

      @publisher.publish
    end

    def test_it_does_nothing_if_message_nil
      sns = mock()
      setup_sns(sns)

      setup_publisher(message: nil)

      @publisher.publish
    end

    def test_publish_to_sns_when_receive_arn
      create_topic_result = mock()
      create_topic_result.expects(:body).returns({ :TopicArn => @arn}.to_json)
      sns = mock()
      sns.expects(:create_topic).with(@topic).returns(create_topic_result)
      sns.expects(:publish).with(@arn, @message)
      setup_sns(sns)

      setup_publisher
      @publisher.publish
    end

    def test_do_not_publish_to_sns_when_no_arn_received
      create_topic_result = mock()
      create_topic_result.expects(:body).returns({ :Error => "some error"}.to_json)
      sns = mock()
      sns.expects(:create_topic).with(@topic).returns(create_topic_result)
      setup_sns(sns)

      setup_publisher
      @publisher.publish
    end

  end
end
