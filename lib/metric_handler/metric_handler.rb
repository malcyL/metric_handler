require 'socket'
require 'fog'
require 'eventmachine'
require 'mongo'
require_relative 'configuration'
require_relative 'message_processor'
require_relative 'message_poster'

include Mongo

module MetricHandler

  class MetricHandler

    def initialize

      @sqs = Fog::AWS::SQS.new(
        :aws_access_key_id => config.access_key,
        :aws_secret_access_key => config.secret_key,
        :region => config.queue_region
      )

      @mongo_client = MongoClient.new(config.mongo_host, config.mongo_port,
                                      :pool_size => 5, :pool_timeout => 5)

      db = @mongo_client.db(config.mongo_metrics_db)
      db.collection("anon_users").create_index( { last_seen: 1 }, { expireAfterSeconds: config.inactive_user_timeout } )
      db.collection("signedin_users").create_index( { last_seen: 1 }, { expireAfterSeconds: config.inactive_user_timeout } )
      db.collection("premium_users").create_index( { last_seen: 1 }, { expireAfterSeconds: config.inactive_user_timeout } )
    end

    def run
      EM.threadpool_size = config.threadpool_size
      EM.run do
        warmup_threads
        loop { run_instance }
      end
    end

    private

    def run_instance
      response = @sqs.receive_message( config.queue_url, options = { 'MaxNumberOfMessages' => 10 } )
      messages = response.body['Message']
      if messages.empty?
        sleep 10
      else
        process_messages(messages)
      end
    end

    def process_messages(messages)
      messages.each do |message|
        EM.defer do
          MessageProcessor.process(message, @mongo_client)
          @sqs.delete_message(config.queue_url, message['ReceiptHandle'])
        end
      end
    end

    def config
      @config ||= Configuration.instance
    end

    def warmup_threads
      EM.defer do
        i = 0
        i += 1
      end
    end
  end

end
