require 'json'
require 'net/http'

module MetricHandler
  class SnsPublisher
    def self.publish(message, topic)
      new(message, topic).publish
    end

    def initialize(message, topic)
      @message = message
      @topic = topic

      @sns = Fog::AWS::SNS.new(
        :aws_access_key_id => config.access_key,
        :aws_secret_access_key => config.secret_key,
        :region => config.queue_region
      )
    end

    def publish
      return if @topic.nil? || @message.nil?

      create_topic_result = @sns.create_topic(@topic)
      body = JSON.parse(create_topic_result.body)
      topic_arn = body['TopicArn']

      unless topic_arn.nil?
        @sns.publish(topic_arn, @message)
      end
    end

    def config
      @config ||= Configuration.instance
    end

  end
end
