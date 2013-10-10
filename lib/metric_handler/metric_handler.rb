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

    def initialize
      @threadpool_size = 100
      @mongo_client = MongoClient.new("localhost", 27017, :pool_size => 5, :pool_timeout => 5)
      db = @mongo_client.db("meducation_metrics")
      db.collection("anon_users").create_index( { last_seen: 1 }, { expireAfterSeconds: 300 } )
      db.collection("signedin_users").create_index( { last_seen: 1 }, { expireAfterSeconds: 300 } )
      db.collection("premium_users").create_index( { last_seen: 1 }, { expireAfterSeconds: 300 } )
    end

    def configure(threadpool_size: 100)
      @threadpool_size = host, port, threadpool_size
    end

    def run
      EM.threadpool_size = @threadpool_size
      EM.run do
        warmup_threads = proc do
          i = 0
          i += 1
        end
        EM.defer(warmup_threads)

        config = YAML.load_file("queue.yaml")

        sqs = Fog::AWS::SQS.new(
         :aws_access_key_id => config['access_key'],
         :aws_secret_access_key => config['secret_key'],
         :region => config['queue_region']
        )

        loop do
          response = sqs.receive_message(config['queue_url'])
          messages = response.body['Message']
          if messages.empty?
            sleep 2
          else
            messages.each do |m|
              operation = proc do
                db = @mongo_client.db("meducation_metrics")
                anon_users_collection = db.collection("anon_users")
                signedin_users_collection = db.collection("signedin_users")
                premium_users_collection = db.collection("premium_users")

                response_body = JSON.parse(m['Body'])
                payload = response_body["payload"]
                session_id = payload["session_id"]
                user_id = payload["user_id"]
                premium = payload["premium"]

                puts payload

                mongo_doc = {
                  _id: session_id,
                  last_seen: Time.now
                }

                if user_id.nil?
                  puts "user_id is nil so adding session_id #{session_id} to anon cache"
                  anon_users_collection.update({"_id" => session_id}, mongo_doc, { upsert: true })
                end

                if !user_id.nil? && !premium
                  puts "user_id is not nil so adding session_id #{session_id} to normal cache"
                  anon_users_collection.remove({"_id" => session_id})
                  signedin_users_collection.update({"_id" => session_id}, mongo_doc, { upsert: true })
                end

                if premium
                  puts "premium so adding session_id #{session_id} to premium cache"
                  anon_users_collection.remove({"_id" => session_id})
                  signedin_users_collection.remove({"_id" => session_id})
                  premium_users_collection.update({"_id" => session_id}, mongo_doc, { upsert: true })
                end

                anon_users_count = anon_users_collection.count
                signedin_users_count = signedin_users_collection.count
                premium_users_count = premium_users_collection.count

                puts "#{anon_users_count} #{signedin_users_count} #{premium_users_count}"

                metrics = {
                  anon: anon_users_count,
                  normal: signedin_users_count,
                  premium: premium_users_count
               }
                dashboard_url = config['dashboard-url']
                post('/events', payload.to_json, dashboard_url)
                post('/metrics/traffic', metrics.to_json, dashboard_url)

                sqs.delete_message(config['queue_url'], m['ReceiptHandle'])
              end
              EM.defer(operation)
            end
          end
        end
      end
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
