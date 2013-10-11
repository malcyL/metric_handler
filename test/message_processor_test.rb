require 'json'
require_relative 'test_helper'

module MetricHandler
  class MessageProcessorTest < Minitest::Test

    def setup
      Configuration.config_filename = 'test/test_config.yml'
      @anon_message = { "Body" => { "payload" => { "session_id" => "1", "user_id" => nil, "premium" => false } } }
      @signedin_message = { "Body" => { "payload" => { "session_id" => "1", "user_id" => "1", "premium" => false } } }
      @premium_message = { "Body" => { "payload" => { "session_id" => "1", "user_id" => "1", "premium" => true } } }
    end

    def test_it_creates
      mongo_client = mock()
      processor = MessageProcessor.new("message", mongo_client)
      refute processor.nil?
    end

    def test_processing_anon_user_message
      anon     = mock(:update => nil, :count => 1)
      signedin = mock(:remove => nil, :count => 0)
      premium  = mock(:remove => nil, :count => 0)

      db = mock('db')
      db.expects(:collection).with("anon_users").returns(anon)
      db.expects(:collection).with("signedin_users").returns(signedin)
      db.expects(:collection).with("premium_users").returns(premium)

      mongo_client = mock( db: db)

      MessagePoster.expects(:post).twice

      processor = MessageProcessor.new({"Body" => @anon_message["Body"].to_json}, mongo_client)
      processor.process
    end
  end
end
