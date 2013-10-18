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
      Propono.config.queue_region = config.queue_region
      Propono.config.application_name = config.application_name
    end

    def run
      Propono.listen_to_queue(config.topic) do |message|
        MessageProcessor.process(message, mongo_client)
      end
    end

    private

    def config
      @config ||= Configuration.instance
    end

    def mongo_client
      @mongo_client ||= MongoClient.new(config.mongo_host, config.mongo_port,
                                        :pool_size => 5, :pool_timeout => 5)
    end
  end
end
