require 'singleton'

module MetricHandler

  class Configuration
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
end
