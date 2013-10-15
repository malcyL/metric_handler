require_relative 'test_helper'

module MetricHandler
  class HandlerTest < Minitest::Test

    def setup
      MetricHandler.configure_from_file 'test/test_config.yml'
    end

    def setup_sqs(sqs = nil)
      Fog::AWS::SQS.expects(:new)
                  .with(:aws_access_key_id     => 'test-aws-access-key',
                        :aws_secret_access_key => 'test-aws-secret-key',
                        :region                => 'test-aws-region')
                  .returns(sqs)
    end

    def setup_mongo
      anon     = mock(create_index: nil)
      signedin = mock(create_index: nil)
      premium  = mock(create_index: nil)
      hour     = mock(create_index: nil)
      day      = mock(create_index: nil)
      week     = mock(create_index: nil)
      month    = mock(create_index: nil)

      db = mock('db')
      db.expects(:collection).with("anon_users").returns(anon)
      db.expects(:collection).with("signedin_users").returns(signedin)
      db.expects(:collection).with("premium_users").returns(premium)
      db.expects(:collection).with("unique_loggedin_last_hour").returns(hour)
      db.expects(:collection).with("unique_loggedin_last_day").returns(day)
      db.expects(:collection).with("unique_loggedin_last_week").returns(week)
      db.expects(:collection).with("unique_loggedin_last_month").returns(month)

      @mongo_client = mock(db: db)
      MongoClient.expects(:new).returns(@mongo_client)
    end

    def setup_handler
      @handler = Handler.new()
    end

    def test_it_creates
      setup_sqs
      setup_mongo
      setup_handler
      refute @handler.nil?
    end

    def test_process_message
      skip 'This fails because event machine is spawning the process in another thread.'
      sqs = mock()
      sqs.expects(:delete_message).twice

      setup_sqs(sqs)
      setup_mongo
      setup_handler

      MessageProcessor.expects(:process)
                      .with('message1', @mongo_client)
      MessageProcessor.expects(:process)
                      .with('message2', @mongo_client)

      @handler.process_messages(['message1', 'message2'])
    end
  end
end
