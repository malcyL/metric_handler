require 'json'
require_relative 'test_helper'

module MetricHandler
  class MessageProcessorTest < Minitest::Test

    def setup
      Configuration.config_filename = 'test/test_config.yml'
      @anon_message = { "Body" => { "payload" => { "session_id" => "1", "user_id" => nil, "premium" => false } } }
      @signedin_message = { "Body" => { "payload" => { "session_id" => "1", "user_id" => "33", "premium" => false } } }
      @premium_message = { "Body" => { "payload" => { "session_id" => "1", "user_id" => "33", "premium" => true } } }
      @session_id = "1"
      @user_id = "33"
    end

    def test_it_creates
      mongo_client = mock()
      processor = MessageProcessor.new("message", mongo_client)
      refute processor.nil?
    end

    def test_processing_anon_user_message
      test_time = setup_test_time

      anon = setup_mock_collection_expecting_update(@session_id, test_time)
      signedin = setup_mock_collection_expecting_remove(@session_id)
      premium = setup_mock_collection_expecting_remove(@session_id)

      hour  = setup_mock_collection_expecting_count_only
      day   = setup_mock_collection_expecting_count_only
      week  = setup_mock_collection_expecting_count_only
      month = setup_mock_collection_expecting_count_only

      mongo_client = setup_mongo_client({"anon_users" => anon,
                                         "signedin_users" => signedin,
                                         "premium_users" => premium,
                                         "unique_loggedin_last_hour" => hour,
                                         "unique_loggedin_last_day" => day,
                                         "unique_loggedin_last_week" => week,
                                         "unique_loggedin_last_month" => month })

      expected_metrics = { anon: 1, normal: 0, premium: 0, unique_loggedin_last_hour: 1, unique_loggedin_last_day: 1, unique_loggedin_last_week: 1, unique_loggedin_last_month: 1 }
      MessagePoster.expects(:post).with("/metrics/traffic", expected_metrics.to_json, "test-dashboard-url")
      expected_event = @anon_message["Body"]["payload"].to_json
      MessagePoster.expects(:post).with("/events", expected_event, "test-dashboard-url")

      processor = MessageProcessor.new({"Body" => @anon_message["Body"].to_json}, mongo_client)
      processor.process
    end

    def test_processing_signedin_user_message
      test_time = setup_test_time

      anon = setup_mock_collection_expecting_remove(@session_id)
      signedin = setup_mock_collection_expecting_update(@session_id, test_time)
      premium = setup_mock_collection_expecting_remove(@session_id)

      hour  = setup_mock_collection_expecting_update(@user_id, test_time)
      day   = setup_mock_collection_expecting_update(@user_id, test_time)
      week  = setup_mock_collection_expecting_update(@user_id, test_time)
      month = setup_mock_collection_expecting_update(@user_id, test_time)

      mongo_client = setup_mongo_client({"anon_users" => anon,
                                         "signedin_users" => signedin,
                                         "premium_users" => premium,
                                         "unique_loggedin_last_hour" => hour,
                                         "unique_loggedin_last_day" => day,
                                         "unique_loggedin_last_week" => week,
                                         "unique_loggedin_last_month" => month })

      expected_metrics = { anon: 0, normal: 1, premium: 0, unique_loggedin_last_hour: 1, unique_loggedin_last_day: 1, unique_loggedin_last_week: 1, unique_loggedin_last_month: 1 }
      MessagePoster.expects(:post).with("/metrics/traffic", expected_metrics.to_json, "test-dashboard-url")
      expected_event = @signedin_message["Body"]["payload"].to_json
      MessagePoster.expects(:post).with("/events", expected_event, "test-dashboard-url")

      processor = MessageProcessor.new({"Body" => @signedin_message["Body"].to_json}, mongo_client)
      processor.process
    end

    def test_processing_premium_user_message
      test_time = setup_test_time

      anon = setup_mock_collection_expecting_remove(@session_id)
      signedin = setup_mock_collection_expecting_remove(@session_id)
      premium = setup_mock_collection_expecting_update(@session_id, test_time)

      hour  = setup_mock_collection_expecting_update(@user_id, test_time)
      day   = setup_mock_collection_expecting_update(@user_id, test_time)
      week  = setup_mock_collection_expecting_update(@user_id, test_time)
      month = setup_mock_collection_expecting_update(@user_id, test_time)

      mongo_client = setup_mongo_client({"anon_users" => anon,
                                         "signedin_users" => signedin,
                                         "premium_users" => premium,
                                         "unique_loggedin_last_hour" => hour,
                                         "unique_loggedin_last_day" => day,
                                         "unique_loggedin_last_week" => week,
                                         "unique_loggedin_last_month" => month })

      expected_metrics = { anon: 0, normal: 0, premium: 1, unique_loggedin_last_hour: 1, unique_loggedin_last_day: 1, unique_loggedin_last_week: 1, unique_loggedin_last_month: 1 }
      MessagePoster.expects(:post).with("/metrics/traffic", expected_metrics.to_json, "test-dashboard-url")
      expected_event = @premium_message["Body"]["payload"].to_json
      MessagePoster.expects(:post).with("/events", expected_event, "test-dashboard-url")

      processor = MessageProcessor.new({"Body" => @premium_message["Body"].to_json}, mongo_client)
      processor.process
    end

    def setup_test_time
      test_time = Time.now
      Time.expects(:now).returns(test_time).at_least_once
      test_time
    end

    def setup_mock_collection_expecting_count_only
      collection = mock()
      collection.expects(:count).returns(1)
      collection
    end

    def setup_mock_collection_expecting_update(id, test_time)
      collection = mock()
      expected_mongo_doc = { _id: id, last_seen: test_time }
      collection.expects(:update).with({ "_id" => id }, expected_mongo_doc, { upsert: true }).returns(nil)
      collection.expects(:count).returns(1)
      collection
    end

    def setup_mock_collection_expecting_remove(session_id)
      collection = mock()
      collection.expects(:remove).with({ "_id" => "1" })
      collection.expects(:count).returns(0)
      collection
    end

    def setup_mongo_client(collections)
      db = mock('db')
      collections.each do |key, collection|
        db.expects(:collection).with(key).returns(collection)
      end
      mongo_client = mock( db: db)
      mongo_client
    end
  end
end
