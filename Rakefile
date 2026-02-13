require 'dotenv/load'
require 'sequel'

namespace :db do
  desc 'Run database migrations'
  task :migrate, [:version] do |_t, args|
    require_relative 'config/database'
    
    Sequel.extension :migration
    version = args[:version].to_i if args[:version]
    
    Sequel::Migrator.run(DB, 'db/migrations', target: version)
    
    # Check which migration table exists
    if DB.table_exists?(:schema_info)
      current_version = DB[:schema_info].first[:version]
    elsif DB.table_exists?(:schema_migrations)
      current_version = DB[:schema_migrations].order(:filename).last[:filename]
    else
      current_version = 'none'
    end
    
    puts "Migration completed. Current schema version: #{current_version}"
  end

  desc 'Rollback database to previous version'
  task :rollback do
    require_relative 'config/database'
    
    Sequel.extension :migration
    current_version = DB[:schema_info].first[:version]
    
    if current_version > 0
      Sequel::Migrator.run(DB, 'db/migrations', target: current_version - 1)
      puts "Rolled back to version #{current_version - 1}"
    else
      puts "Already at version 0"
    end
  end

  desc 'Create a new migration file'
  task :create_migration, [:name] do |_t, args|
    unless args[:name]
      puts "Usage: rake db:create_migration[migration_name]"
      exit 1
    end
    
    timestamp = Time.now.strftime('%Y%m%d%H%M%S')
    filename = "db/migrations/#{timestamp}_#{args[:name]}.rb"
    
    File.open(filename, 'w') do |f|
      f.write <<~MIGRATION
        Sequel.migration do
          change do
            # Add your migration code here
          end
        end
      MIGRATION
    end
    
    puts "Created migration: #{filename}"
  end

  desc 'Drop all tables (use with caution!)'
  task :reset do
    require_relative 'config/database'
    
    DB.tables.each do |table|
      DB.drop_table(table, cascade: true)
    end
    
    puts "All tables dropped"
  end

  desc 'Show current schema version'
  task :version do
    require_relative 'config/database'
    
    if DB.table_exists?(:schema_info)
      version = DB[:schema_info].first[:version]
      puts "Current schema version: #{version}"
    elsif DB.table_exists?(:schema_migrations)
      version = DB[:schema_migrations].order(:filename).last[:filename]
      puts "Current schema version: #{version}"
    else
      puts "No migrations have been run yet"
    end
  end

  desc 'Create database'
  task :create do
    db_url = ENV.fetch('DATABASE_URL')
    db_name = db_url.split('/').last
    
    # Connect to postgres database to create the target database
    admin_url = db_url.gsub(/\/[^\/]+$/, '/postgres')
    admin_db = Sequel.connect(admin_url)
    
    begin
      admin_db.execute("CREATE DATABASE #{db_name}")
      puts "Database '#{db_name}' created successfully"
    rescue Sequel::DatabaseError => e
      if e.message.include?('already exists')
        puts "Database '#{db_name}' already exists"
      else
        raise
      end
    ensure
      admin_db.disconnect
    end
  end

  desc 'Drop database'
  task :drop do
    db_url = ENV.fetch('DATABASE_URL')
    db_name = db_url.split('/').last
    
    # Connect to postgres database to drop the target database
    admin_url = db_url.gsub(/\/[^\/]+$/, '/postgres')
    admin_db = Sequel.connect(admin_url)
    
    begin
      admin_db.execute("DROP DATABASE IF EXISTS #{db_name}")
      puts "Database '#{db_name}' dropped successfully"
    rescue Sequel::DatabaseError => e
      puts "Error dropping database: #{e.message}"
    ensure
      admin_db.disconnect
    end
  end
end

desc 'Start the application server'
task :server do
  exec 'bundle exec puma config.ru -p 9292'
end

desc 'Open console with database connection'
task :console do
  require 'pry'
  require_relative 'config/database'
  
  # Load all models
  Dir['./app/models/**/*.rb'].each { |f| require f }
  
  puts "Database connected. DB object available."
  puts "Models loaded from app/models/"
  
  Pry.start
end
