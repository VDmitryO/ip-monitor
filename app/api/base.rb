require 'grape'
require 'grape_logging'
require_relative 'v1/root'
require_relative '../utils/logger'

module App
  module API
    class Base < Grape::API
      format :json
      content_type :json, 'application/json'

      # Use grape_logging middleware with SemanticLogger
      logger.formatter = GrapeLogging::Formatters::Default.new
      insert_before Grape::Middleware::Error, GrapeLogging::Middleware::RequestLogger, { logger: SemanticLogger['API'] }

      # Global error handlers
      rescue_from Grape::Exceptions::ValidationErrors do |e|
        App::Logger.warn "Validation error", errors: e.full_messages
        error!({ error: 'Validation failed', details: e.full_messages }, 400)
      end

      rescue_from Sequel::NoMatchingRow do |e|
        App::Logger.warn "Record not found", path: request.path_info
        error!({ error: 'Record not found' }, 404)
      end

      rescue_from Sequel::ValidationFailed do |e|
        App::Logger.warn "Validation failed", error: e.message
        error!({ error: 'Validation failed', details: e.message }, 422)
      end

      rescue_from :all do |e|
        App::Logger.error "Unhandled exception",
          error: e.class.name,
          message: e.message,
          backtrace: e.backtrace&.first(10)
        if ENV['RACK_ENV'] == 'development'
          error!({ error: e.class.name, message: e.message, backtrace: e.backtrace[0..5] }, 500)
        else
          error!({ error: 'Internal server error' }, 500)
        end
      end

      # Health check endpoint
      get '/health' do
        { status: 'ok', timestamp: Time.now.utc.iso8601 }
      end

      # Mount API versions
      mount V1::Root
    end
  end
end
