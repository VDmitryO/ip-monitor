require 'sequel'
require 'logger'

# Database connection
DB = Sequel.connect(
  ENV.fetch('DATABASE_URL'),
  max_connections: ENV.fetch('DB_MAX_CONNECTIONS', 10).to_i,
  logger: Logger.new($stdout)
)

# Enable Sequel extensions
Sequel.extension :migration

# Set timezone to UTC
Sequel.default_timezone = :utc

# Test connection
DB.test_connection

puts "Database connected: #{DB.opts[:database]}"
