require 'dotenv/load'
require 'rack/cors'
require_relative 'config/database'
require_relative 'app/api/base'

use Rack::Cors do
  allow do
    origins '*'
    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end

run App::API::Base
