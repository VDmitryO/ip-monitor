require 'semantic_logger'

# Configure SemanticLogger
SemanticLogger.default_level = ENV.fetch('LOG_LEVEL', 'info').to_sym

# Use JSON formatter in production, color in development
formatter = ENV.fetch('LOG_FORMAT', ENV['RACK_ENV'] == 'production' ? 'json' : 'color').to_sym

SemanticLogger.add_appender(
  io: $stdout,
  formatter: formatter
)
