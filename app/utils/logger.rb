require 'semantic_logger'

module App
  # Centralized logger wrapper using SemanticLogger
  # Provides structured logging with JSON output support
  #
  # Usage:
  #   App::Logger.info "Message", key: "value"
  #   App::Logger.error "Error occurred", error: e.message
  #   App::Logger.measure("Operation") { do_something }
  #
  class Logger
    include SemanticLogger::Loggable

    class << self
      # Delegate logging methods to the logger instance
      %i[debug info warn error fatal trace].each do |level|
        define_method(level) do |message = nil, payload = nil, &block|
          logger.send(level, message, payload, &block)
        end
      end

      # Measure and log the duration of a block
      # @param message [String] Description of the operation
      # @param level [Symbol] Log level (default: :info)
      # @param payload [Hash] Additional structured data
      def measure(message, level: :info, payload: nil)
        logger.measure(level, message, payload: payload) { yield }
      end

      # Log with context - useful for adding consistent metadata
      def with_context(context)
        logger.push_context(context)
        yield
      ensure
        logger.pop_context
      end
    end
  end
end
