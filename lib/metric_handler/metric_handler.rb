require 'singleton'
require 'socket'
require 'fog'
require 'eventmachine'
require 'json'
require 'net/http'
require 'uri'
require 'mongo'

include Mongo

module MetricHandler

  class Configurator
    include Singleton

    attr_accessor :threadpool_size, :dashboard_url, :inactive_user_timeout,
                  :access_key, :secret_key, :queue_region, :queue_url,
                  :mongo_host, :mongo_port, :mongo_metrics_db

    def initialize
      config = YAML.load_file("config.yml")

      @threadpool_size = config.fetch('em_threadpool', 100)
      @dashboard_url = config['dashboard_url']
      @inactive_user_timeout = config.fetch('inactive_user_timeout', 300)

      @access_key = ensure_configured( config, 'access_key' )
      @secret_key = ensure_configured( config, 'secret_key' )
      @queue_region = ensure_configured( config, 'queue_region' )
      @queue_url = ensure_configured( config, 'queue_url' )

      @mongo_host = config.fetch('mongo_host', 'localhost')
      @mongo_port = config.fetch('mongo_port', 27017)
      @mongo_metrics_db = config.fetch('mongo_metrics_db', 'meducation_metrics')
    end

    private
    def ensure_configured(config, key)
      if config[key].nil? || config[key].empty?
        raise "Configuration in config.yml should contain #{key}"
      end

      config[key]
    end
  end

  class MetricHandler

    def initialize
      config

      @sqs = Fog::AWS::SQS.new(
        :aws_access_key_id => @config.access_key,
        :aws_secret_access_key => @config.secret_key,
        :region => @config.queue_region
      )

      @mongo_client = MongoClient.new(@config.mongo_host, @config.mongo_port,
                                      :pool_size => 5, :pool_timeout => 5)

      db = @mongo_client.db(@config.mongo_metrics_db)
      db.collection("anon_users").create_index( { last_seen: 1 }, { expireAfterSeconds: @config.inactive_user_timeout } )
      db.collection("signedin_users").create_index( { last_seen: 1 }, { expireAfterSeconds: @config.inactive_user_timeout } )
      db.collection("premium_users").create_index( { last_seen: 1 }, { expireAfterSeconds: @config.inactive_user_timeout } )
    end

    def run
      EM.threadpool_size = @config.threadpool_size
      EM.run do
        warmup_threads
        loop { run_instance }
      end
    end

    private

    def run_instance
      response = @sqs.receive_message( @config.queue_url, options = { 'MaxNumberOfMessages' => 10 } )
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
          @sqs.delete_message(@config.queue_url, message['ReceiptHandle'])
        end
      end
    end

    def config
      @config ||= Configurator.instance
    end

    def warmup_threads
      EM.defer do
        i = 0
        i += 1
      end
    end
  end

  class MessageProcessor

    def self.process(message, mongo_client)
      new(message, mongo_client).process
    end

    def initialize(message, mongo_client)
      config
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

      MessagePoster.post('/events', payload.to_json, @config.dashboard_url)
      MessagePoster.post('/metrics/traffic', metrics.to_json, @config.dashboard_url)
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
      @config ||= Configurator.instance
    end
  end

  class MessagePoster
    def self.post(path, body, url)
      new(path, body, url).post
    end

    def initialize(path, body, url)
      @path = path
      @body = body
      @url  = url
    end

    def post
      return if @url.nil?

      http = Net::HTTP.new(@url, 80)
      headers = {"Content-Type" => "application/json" }
      response = http.post(@path, @body, headers)

      if response.code != '200'
        puts @path
        puts response
      end
    end
  end
end
