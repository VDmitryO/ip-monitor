require 'sequel'
require_relative 'semantic_logger'
require_relative '../app/utils/logger'

# Database connection
DB = Sequel.connect(
  ENV.fetch('DATABASE_URL'),
  max_connections: ENV.fetch('DB_MAX_CONNECTIONS', 10).to_i,
  logger: SemanticLogger['Sequel']
)

# Enable Sequel extensions
Sequel.extension :migration

# Set timezone to UTC
Sequel.default_timezone = :utc

# Test connection
DB.test_connection

App::Logger.info "Database connected", database: DB.opts[:database]
