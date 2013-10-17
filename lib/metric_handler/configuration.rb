require 'singleton'

module MetricHandler

  class ConfigurationError < Exception
  end

  class Configuration
    include Singleton

    OPTIONAL_SETTINGS = [:threadpool_size, :dashboard_url, :inactive_user_timeout,
                         :mongo_host, :mongo_port, :mongo_metrics_db]

    COMPULSORY_SETTINGS = [:access_key, :secret_key, :queue_region, :queue_url]

    attr_accessor *OPTIONAL_SETTINGS
    attr_writer *COMPULSORY_SETTINGS

    def initialize
      @threadpool_size = 100
      @dashboard_url = nil
      @inactive_user_timeout = 300

      @mongo_host = 'localhost'
      @mongo_port = 27017
      @mongo_metrics_db = 'meducation_metrics'
    end

    def configure_from_file(file)
      config = YAML.load_file(file)
      [OPTIONAL_SETTINGS, COMPULSORY_SETTINGS].flatten.each do |setting|
        if val = config[setting.to_s]
          instance_variable_set("@#{setting.to_s}", val)
        end
      end
    end

    COMPULSORY_SETTINGS.each do |setting|
      define_method setting do
        get_or_raise(setting)
      end
    end

    private

    def get_or_raise(setting)
      if val = instance_variable_get("@#{setting.to_s}")
        val
      else
        raise ConfigurationError.new("Configuration for #{setting} is not set")
      end
    end
  end
end
