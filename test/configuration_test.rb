require_relative 'test_helper'

module MetricHandler
  class ConfigurationTest < Minitest::Test

    def config
      @config ||= Configuration.send(:new)
    end

    def test_obtaining_singletion
      refute config.nil?
    end

    def test_unable_to_create_instance
      assert_raises(NoMethodError) do
        config = Configuration.new
      end
    end

    def test_values_read_from_file
      config.configure_from_file 'test/test_config.yml'
      assert_equal 'test-aws-access-key', config.access_key
      assert_equal 'test-aws-secret-key', config.secret_key
      assert_equal 'test-aws-sqs-url', config.queue_url
      assert_equal 'test-aws-region', config.queue_region
      assert_equal 'test-dashboard-url', config.dashboard_url
      assert_equal 999, config.threadpool_size
      assert_equal 'mongohost', config.mongo_host
      assert_equal 88888, config.mongo_port
      assert_equal 'test-mongo-db', config.mongo_metrics_db
      assert_equal 666, config.inactive_user_timeout
    end

    def test_access_key_is_writable
      val = "Foobar"
      config.access_key = val
      assert_equal val, config.access_key
    end

    def test_missing_access_key_throws_exception
      assert_raises(ConfigurationError) do
        config.access_key
      end
    end

    def test_missing_secret_key_throws_exception
      assert_raises(ConfigurationError) do
        config.secret_key
      end
    end

    def test_missing_queue_region_throws_exception
      assert_raises(ConfigurationError) do
        config.queue_region
      end
    end

    def test_missing_queue_url_throws_exception
      assert_raises(ConfigurationError) do
        config.queue_url
      end
    end
  end
end
