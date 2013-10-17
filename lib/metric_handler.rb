require "metric_handler/version"
require "metric_handler/configuration"
require "metric_handler/handler"

module MetricHandler
  def self.config
    Configuration.instance
  end

  def self.configure_from_file(filepath)
    Configuration.instance.configure_from_file(filepath)
  end
end
