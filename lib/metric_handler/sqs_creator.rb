require 'net/http'

module MetricHandler
  class SqsCreator
    def self.create(name)
      new(name).create
    end

    def initialize(name)
      @name = name

      @sqs = Fog::AWS::SQS.new(
        :aws_access_key_id => config.access_key,
        :aws_secret_access_key => config.secret_key,
        :region => config.queue_region
      )
    end

    def create
      return if @name.nil? 

      create_queue_result = @sqs.create_queue(@name)
      body = create_queue_result.body
      puts body
    end

    def config
      @config ||= Configuration.instance
    end

  end
end
