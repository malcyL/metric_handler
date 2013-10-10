require 'json'
require 'mongo'
require_relative 'configuration'

include Mongo

module MetricHandler

  class MessageProcessor

    def self.process(message, mongo_client)
      new(message, mongo_client).process
    end

    def initialize(message, mongo_client)
      @message = message
      @mongo_client = mongo_client
    end

    def process
      db = @mongo_client.db("meducation_metrics")
      anon_users = db.collection("anon_users")
      signedin_users = db.collection("signedin_users")
      premium_users = db.collection("premium_users")

      response_body = JSON.parse(@message['Body'])
      payload = response_body["payload"]
      session_id = payload["session_id"]
      user_id = payload["user_id"]
      premium = payload["premium"]

      if user_id.nil?
        uniquely_in_one( session_id, anon_users, [signedin_users, premium_users] )
      elsif !user_id.nil? && !premium
        uniquely_in_one( session_id, signedin_users, [anon_users, premium_users] )
      elsif premium
        uniquely_in_one( session_id, premium_users, [anon_users, signedin_users] )
      end

      metrics = { anon: anon_users.count, normal: signedin_users.count, premium: premium_users.count }
      puts metrics

      MessagePoster.post('/events', payload.to_json, config.dashboard_url)
      MessagePoster.post('/metrics/traffic', metrics.to_json, config.dashboard_url)
    end

    private
    def uniquely_in_one(id, add, remove)
      mongo_doc = { _id: id, last_seen: Time.now }
      add.update( { "_id" => id }, mongo_doc, { upsert: true })
      remove.each do |r|
        r.remove({"_id" => id})
      end
    end

    def config
      @config ||= Configuration.instance
    end
  end
end
