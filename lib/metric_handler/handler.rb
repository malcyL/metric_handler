require 'socket'
require 'fog'
require 'mongo'
require_relative 'configuration'
require_relative 'message_processor'

include Mongo

module MetricHandler

  class Handler

    def initialize
      db = mongo_client.db(config.mongo_metrics_db)

      %w{anon_users signedin_users premium_users}.each do |collection|
        db.collection(collection).create_index( { last_seen: 1 }, { expireAfterSeconds: config.inactive_user_timeout } )
      end

      db.collection("unique_loggedin_last_hour").create_index( { last_seen: 1 }, { expireAfterSeconds: (60 * 60) } )
      db.collection("unique_loggedin_last_day").create_index( { last_seen: 1 }, { expireAfterSeconds: (60 * 60 * 24) } )
      db.collection("unique_loggedin_last_week").create_index( { last_seen: 1 }, { expireAfterSeconds: (60 * 60 * 24 * 7) } )
      db.collection("unique_loggedin_last_month").create_index( { last_seen: 1 }, { expireAfterSeconds: (60 * 60 * 24 * 30) } )

      Propono.config.access_key = config.access_key
      Propono.config.secret_key = config.secret_key
      Propono.config.queue_url = config.queue_url
      Propono.config.queue_region = config.queue_region
    end

    def run
      loop { run_instance }
    end

    private

    def run_instance
      response = sqs.receive_message( config.queue_url, options = { 'MaxNumberOfMessages' => 10 } )
      messages = response.body['Message']
      if messages.empty?
        sleep 10
      else
        process_messages(messages)
      end
    end

    def process_messages(messages)
      messages.each do |message|
        Thread.new { process_message(message) }
      end
    end

    def process_message(message)
      MessageProcessor.process(message, mongo_client)
      sqs.delete_message(config.queue_url, message['ReceiptHandle'])
    end

    def config
      @config ||= Configuration.instance
    end

    def sqs
      @sqs ||= Fog::AWS::SQS.new(
        :aws_access_key_id => config.access_key,
        :aws_secret_access_key => config.secret_key,
        :region => config.queue_region
      )
    end

    def mongo_client
      @mongo_client ||= MongoClient.new(config.mongo_host, config.mongo_port,
                                        :pool_size => 5, :pool_timeout => 5)
    end
  end
end
