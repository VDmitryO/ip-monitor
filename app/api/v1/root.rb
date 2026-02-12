require 'grape'
require_relative 'ips'

module App
  module API
    module V1
      class Root < Grape::API
        version 'v1', using: :path
        format :json
        prefix :api

        # Example endpoint
        desc 'Returns API information'
        get '/' do
          {
            api: 'IP Monitor API',
            version: 'v1',
            endpoints: [
              { method: 'GET', path: '/api/v1/', description: 'API information' },
              { method: 'GET', path: '/health', description: 'Health check' },
              { method: 'POST', path: '/api/v1/ips', description: 'Create IP address' },
              { method: 'POST', path: '/api/v1/ips/:id/enable', description: 'Enable IP monitoring' },
              { method: 'POST', path: '/api/v1/ips/:id/disable', description: 'Disable IP monitoring' },
              { method: 'DELETE', path: '/api/v1/ips/:id', description: 'Delete IP address' }
            ]
          }
        end

        # Mount resource endpoints
        mount App::API::V1::Ips

        # Add your resource endpoints here
        # Example:
        # namespace :users do
        #   desc 'Get all users'
        #   get do
        #     DB[:users].all
        #   end
        #
        #   desc 'Get a specific user'
        #   params do
        #     requires :id, type: Integer, desc: 'User ID'
        #   end
        #   get ':id' do
        #     DB[:users].where(id: params[:id]).first || error!('Not found', 404)
        #   end
        #
        #   desc 'Create a new user'
        #   params do
        #     requires :name, type: String, desc: 'User name'
        #     requires :email, type: String, desc: 'User email'
        #   end
        #   post do
        #     user_id = DB[:users].insert(
        #       name: params[:name],
        #       email: params[:email],
        #       created_at: Time.now
        #     )
        #     DB[:users].where(id: user_id).first
        #   end
        # end
      end
    end
  end
end
