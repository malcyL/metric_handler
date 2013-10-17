require 'json'
require 'mongo'
require 'propono'
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
      retrieve_current_values
      extract_payload
      update_collections
      send_payload
      send_metrics
    end

    private

    def retrieve_current_values
      @anon_users     = db.collection("anon_users")
      @signedin_users = db.collection("signedin_users")
      @premium_users  = db.collection("premium_users")

      @unique_loggedin_last_hour  = db.collection("unique_loggedin_last_hour")
      @unique_loggedin_last_day   = db.collection("unique_loggedin_last_day")
      @unique_loggedin_last_week  = db.collection("unique_loggedin_last_week")
      @unique_loggedin_last_month = db.collection("unique_loggedin_last_month")
    end

    def extract_payload
      response_body = JSON.parse(@message['Body'])
      @payload = response_body["payload"]
      @session_id = @payload["session_id"]
      @user_id = @payload["user_id"]
      @premium = @payload["premium"]
    end

    def update_collections
      if @user_id.nil?
        uniquely_in_one( @session_id, @anon_users, [@signedin_users, @premium_users] )
      elsif !@user_id.nil? && !@premium
        uniquely_in_one( @session_id, @signedin_users, [@anon_users, @premium_users] )
      elsif @premium
        uniquely_in_one( @session_id, @premium_users, [@anon_users, @signedin_users] )
      end
      update_loggedin_user_collections
    end

    def send_payload
      Propono.publish("events", @payload.to_json)
    end

    def send_metrics
      metrics = { anon: @anon_users.count,
                  normal: @signedin_users.count,
                  premium: @premium_users.count,
                  unique_loggedin_last_hour: @unique_loggedin_last_hour.count,
                  unique_loggedin_last_day: @unique_loggedin_last_day.count,
                  unique_loggedin_last_week: @unique_loggedin_last_week.count,
                  unique_loggedin_last_month: @unique_loggedin_last_month.count
                }
      puts metrics

      Propono.publish("metrics-traffic", metrics.to_json)
    end

    def update_loggedin_user_collections
      return if @user_id.nil?
      [@unique_loggedin_last_hour,
       @unique_loggedin_last_day,
       @unique_loggedin_last_week,
       @unique_loggedin_last_month].each do |collection|
         update_collection(collection)
      end
    end

    def update_collection(collection)
      collection.update(
        { "_id" => @user_id },
        { _id: @user_id, last_seen: Time.now },
        {upsert: true}
      )
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

    def db
      @db ||= @mongo_client.db("meducation_metrics")
    end
  end
end
