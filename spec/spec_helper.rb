require 'rack/test'
require 'rspec'
require 'dotenv/load'
require 'factory_bot'

ENV['RACK_ENV'] = 'test'
ENV['DATABASE_URL'] ||= 'postgres://localhost/ip_monitor_test'

require_relative '../config/database'

# Load all models
Dir[File.join(__dir__, '../app/models/**/*.rb')].each { |f| require f }

require_relative '../app/api/base'

# Load factories
FactoryBot.find_definitions

module RSpecMixin
  include Rack::Test::Methods
  
  def app
    App::API::Base
  end
end

RSpec.configure do |config|
  config.include RSpecMixin
  config.include FactoryBot::Syntax::Methods

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.disable_monkey_patching!
  config.warnings = true
  
  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed

  # Database cleanup
  config.around(:each) do |example|
    DB.transaction(rollback: :always, auto_savepoint: true) do
      example.run
    end
  end
end
