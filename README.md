# IP Monitor API

A RESTful API built with Grape, Sequel, and PostgreSQL.

## Tech Stack

- **Framework**: [Grape](https://github.com/ruby-grape/grape) - REST API framework
- **ORM**: [Sequel](https://sequel.jeremyevans.net/) - Database toolkit
- **Database**: PostgreSQL
- **Server**: Puma
- **Testing**: RSpec + Rack::Test

## Prerequisites

- Docker
- Docker Compose

## Setup & Running

Run the application with Docker Compose:

```bash
docker compose up --build
```

That's it! The application will:
- Start PostgreSQL database
- Run migrations automatically
- Start the API server

The API will be available at `http://localhost:9292`

### Useful Docker Commands

```bash
# Start in background
docker compose up -d

# View logs
docker compose logs -f app

# Stop containers
docker compose down

# Stop and remove database volume
docker compose down -v

# Open console
docker compose exec app bundle exec rake console
```

## API Endpoints

### Health Check
```bash
GET /health
```

### API Info
```bash
GET /api/v1/
```

## Database Tasks

### Create a new migration
```bash
bundle exec rake db:create_migration[create_users]
```

### Run migrations
```bash
bundle exec rake db:migrate
```

### Rollback last migration
```bash
bundle exec rake db:rollback
```

### Check current schema version
```bash
bundle exec rake db:version
```

### Reset database (drop all tables)
```bash
bundle exec rake db:reset
```

## Console

Open an interactive console with database connection:

```bash
bundle exec rake console
```

## Testing

### Running Tests with Docker Compose (Recommended)

Run the full test suite with Docker Compose:

```bash
docker compose run --rm test
```

This will:
- Create the test database (`ip_monitor_test`)
- Run migrations
- Execute all RSpec tests
- Clean up after completion

Run specific test file:

```bash
docker compose run --rm test bundle exec rspec spec/requests/v1/ips_spec.rb
```

Run tests with specific options:

```bash
# Run with documentation format
docker compose run --rm test bundle exec rspec --format documentation

# Run only failed tests
docker compose run --rm test bundle exec rspec --only-failures
```

### Running Tests Locally

If you have Ruby and PostgreSQL installed locally:

```bash
# Set up test database
RACK_ENV=test bundle exec rake db:create
RACK_ENV=test bundle exec rake db:migrate

# Run tests
bundle exec rspec
```

## Project Structure

```
.
├── app/
│   ├── api/
│   │   ├── base.rb           # Main API class
│   │   └── v1/
│   │       └── root.rb       # V1 API endpoints
│   └── models/               # Sequel models
├── config/
│   └── database.rb           # Database configuration
├── db/
│   └── migrations/           # Database migrations
├── spec/
│   └── spec_helper.rb        # RSpec configuration
├── config.ru                 # Rack configuration
├── Gemfile                   # Dependencies
├── Rakefile                  # Rake tasks
└── README.md
```

## Adding New Endpoints

1. Create a new file in `app/api/v1/` (e.g., `users.rb`)
2. Define your endpoints using Grape DSL
3. Mount it in `app/api/v1/root.rb`

Example:

```ruby
# app/api/v1/users.rb
module App
  module API
    module V1
      class Users < Grape::API
        namespace :users do
          desc 'Get all users'
          get do
            DB[:users].all
          end
        end
      end
    end
  end
end

# Mount in app/api/v1/root.rb
mount Users
```

## Creating Models

Create Sequel models in `app/models/`:

```ruby
# app/models/user.rb
class User < Sequel::Model
  plugin :validation_helpers
  plugin :timestamps, update_on_create: true

  def validate
    super
    validates_presence [:name, :email]
    validates_unique :email
  end
end
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `DATABASE_URL` | PostgreSQL connection string | Required |
| `RACK_ENV` | Environment (development/test/production) | `development` |
| `PORT` | Server port | `9292` |
| `DB_MAX_CONNECTIONS` | Database connection pool size | `10` |

## Error Handling

The API includes global error handlers for:

- Validation errors (400)
- Not found errors (404)
- Database validation errors (422)
- Internal server errors (500)

In development mode, detailed error information including backtraces is returned.

## CORS

CORS is enabled for all origins by default. Configure in [`config.ru`](config.ru:4) if needed.

## License

MIT
