require_relative 'test_helper'

module MetricHandler
  class ConfigurationTest < Minitest::Test

    def setup_config
      Configuration.config_filename = 'test/test_config.yml'
      @config = Configuration.instance
    end

    def test_obtaining_singletion
      setup_config
      refute @config.nil?
    end

    def test_unable_to_create_instance
      assert_raises(NoMethodError) {
        config = Configuration.new
      }
    end

    def test_values_read_from_file
      setup_config
      assert_equal @config.access_key, 'test-aws-access-key'
      assert_equal @config.secret_key, 'test-aws-secret-key'
      assert_equal @config.queue_url, 'test-aws-sqs-url'
      assert_equal @config.queue_region, 'test-aws-region'
      assert_equal @config.dashboard_url, 'test-dashboard-url'
      assert_equal @config.threadpool_size, 999
      assert_equal @config.mongo_host, 'mongohost'
      assert_equal @config.mongo_port, 88888
      assert_equal @config.mongo_metrics_db, 'test-mongo-db'
      assert_equal @config.inactive_user_timeout, 666
    end

    def test_missing_access_key_throws_exception
      skip('How do we test invalid configuration files when this is a singleton?')
      assert_raises(Exception) {
        config = Configuration.instance
      }
    end

    def test_missing_secret_key_throws_exception
      skip('How do we test invalid configuration files when this is a singleton?')
      assert_raises(Exception) {
        config = Configuration.instance
      }
    end

    def test_missing_queue_region_throws_exception
      skip('How do we test invalid configuration files when this is a singleton?')
      assert_raises(Exception) {
        config = Configuration.instance
      }
    end

    def test_missing_queue_url_throws_exception
      skip('How do we test invalid configuration files when this is a singleton?')
      assert_raises(Exception) {
        config = Configuration.instance
      }
    end

  end
end
