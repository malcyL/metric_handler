require 'socket'
require 'fog'
require 'eventmachine'
require 'json'
require 'net/http'
require 'uri'
require 'mongo'

include Mongo

module MetricHandler

  class MetricHandler

    def ensure_configured(config, key)
      if config[key].nil? || config[key].empty?
        raise "Configuration in config.yml should contain #{key}"
      end
      return config[key]
    end

    def initialize
      config = YAML.load_file("config.yml")
      @threadpool_size = config.fetch('em_threadpool', 100)
      @mongo_client = MongoClient.new(config.fetch('mongo_host', 'localhost'),
                                      config.fetch('mongo_port', 27017),
                                      :pool_size => 5, :pool_timeout => 5)
      db = @mongo_client.db(config.fetch('mongo_metrics_db', 'meducation_metrics'))
      inactive_user_timeout = config.fetch('inactive_user_timeout', 300)
      db.collection("anon_users").create_index( { last_seen: 1 }, { expireAfterSeconds: inactive_user_timeout } )
      db.collection("signedin_users").create_index( { last_seen: 1 }, { expireAfterSeconds: inactive_user_timeout } )
      db.collection("premium_users").create_index( { last_seen: 1 }, { expireAfterSeconds: inactive_user_timeout } )
      @dashboard_url = config['dashboard_url']
      access_key = ensure_configured( config, 'access_key' )
      secret_key = ensure_configured( config, 'secret_key' )
      queue_region = ensure_configured( config, 'queue_region' )
      @queue_url = ensure_configured( config, 'queue_url' )
      @sqs = Fog::AWS::SQS.new(
        :aws_access_key_id => access_key,
        :aws_secret_access_key => secret_key,
        :region => queue_region
      )
    end

    def configure(threadpool_size: 100)
      @threadpool_size = threadpool_size
    end

    def warmup_threads
      EM.defer do
        i = 0
        i += 1
      end
    end

    def uniquely_in_one(id, add, remove)
      mongo_doc = { _id: id, last_seen: Time.now }
      add.update( { "_id" => id }, mongo_doc, { upsert: true })
      remove.each do |r|
        r.remove({"_id" => id})
      end
    end

    def run
      EM.threadpool_size = @threadpool_size
      EM.run do
        warmup_threads

        loop do
          response = @sqs.receive_message( @queue_url, options = { 'MaxNumberOfMessages' => 10 } )
          messages = response.body['Message']
          if messages.empty?
            sleep 10
          else
            messages.each do |m|
              process_message(m)
            end
          end
        end
      end
    end

    def process_message ( m )
      operation = proc do
        db = @mongo_client.db("meducation_metrics")
        anon_users = db.collection("anon_users")
        signedin_users = db.collection("signedin_users")
        premium_users = db.collection("premium_users")

        response_body = JSON.parse(m['Body'])
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
        post('/events', payload.to_json, @dashboard_url)
        post('/metrics/traffic', metrics.to_json, @dashboard_url)

        @sqs.delete_message(@queue_url, m['ReceiptHandle'])
      end
      EM.defer(operation)
    end

    def post(path, body, url)
      if !url.nil?
        http = Net::HTTP.new(url, 80)
        headers = {"Content-Type" => "application/json" }
        response = http.post(path, body, headers)

        if response.code != '200'
          puts path
          puts response
        end
      end
    end

  end
end
