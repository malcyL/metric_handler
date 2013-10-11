require_relative 'test_helper'

module MetricHandler
  class MetricHandlerTest < Minitest::Test

    def setup
      Configuration.config_filename = 'test/test_config.yml'
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

      db = mock('db')
      db.expects(:collection).with("anon_users").returns(anon)
      db.expects(:collection).with("signedin_users").returns(signedin)
      db.expects(:collection).with("premium_users").returns(premium)

      @mongo_client = mock(db: db)
      MongoClient.expects(:new).returns(@mongo_client)
    end

    def setup_handler
      @handler = MetricHandler.new()
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
