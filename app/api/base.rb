require 'grape'
require_relative 'v1/root'

module App
  module API
    class Base < Grape::API
      format :json
      content_type :json, 'application/json'
      
      # Global error handlers
      rescue_from Grape::Exceptions::ValidationErrors do |e|
        error!({ error: 'Validation failed', details: e.full_messages }, 400)
      end

      rescue_from Sequel::NoMatchingRow do |e|
        error!({ error: 'Record not found' }, 404)
      end

      rescue_from Sequel::ValidationFailed do |e|
        error!({ error: 'Validation failed', details: e.message }, 422)
      end

      rescue_from :all do |e|
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
