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

      unique_loggedin_last_hour  = db.collection("unique_loggedin_last_hour")
      unique_loggedin_last_day   = db.collection("unique_loggedin_last_day")
      unique_loggedin_last_week  = db.collection("unique_loggedin_last_week")
      unique_loggedin_last_month = db.collection("unique_loggedin_last_month")
      unique_loggedin_collections = [ unique_loggedin_last_hour,
                                      unique_loggedin_last_day,
                                      unique_loggedin_last_week,
                                      unique_loggedin_last_month ]

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

      update_loggedin_user_collections(user_id, unique_loggedin_collections)

      metrics = { anon: anon_users.count,
                  normal: signedin_users.count,
                  premium: premium_users.count,
                  unique_loggedin_last_hour: unique_loggedin_last_hour.count,
                  unique_loggedin_last_day: unique_loggedin_last_day.count,
                  unique_loggedin_last_week: unique_loggedin_last_week.count,
                  unique_loggedin_last_month: unique_loggedin_last_month.count
                }
      puts metrics

      MessagePoster.post('/events', payload.to_json, config.dashboard_url)
      MessagePoster.post('/metrics/traffic', metrics.to_json, config.dashboard_url)
      SnsPublisher.publish(payload.to_json, 'events')
      SnsPublisher.publish(metrics.to_json, 'metrics-traffic')
    end

    private
    def update_loggedin_user_collections(user_id, collections)
      if !user_id.nil?
        collections.each { |c| c.update( { "_id" => user_id },
                                         { _id: user_id, last_seen: Time.now },
                                         {upsert: true} ) }
      end
    end

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
