require_relative "metric_handler/version"
require_relative "metric_handler/configuration"
require_relative "metric_handler/handler"
require_relative "metric_handler/sqs_creator"

module MetricHandler
  def self.config
    Configuration.instance
  end

  def self.configure_from_file(filepath)
    Configuration.instance.configure_from_file(filepath)
  end
end
