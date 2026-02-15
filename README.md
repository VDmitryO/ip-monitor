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

## Ping Worker

The application includes a background worker that continuously monitors IP addresses by pinging them at regular intervals.

### How It Works

1. **Batch Processing**: The worker selects a batch of IPs that are due for checking (based on `next_check_at`)
2. **Parallel Workers**: Multiple worker instances can run in parallel using PostgreSQL's `FOR UPDATE SKIP LOCKED` to prevent conflicts
3. **Timeout Enforcement**: Each ping has a 1-second timeout (hard requirement)
4. **Result Recording**: All ping results are saved to the `ping_checks` table

### Running the Worker

The worker is automatically started with Docker Compose:

```bash
docker compose up
```

To scale workers (run multiple instances in parallel):

```bash
docker compose up --scale ping-worker=3
```

### Configuration

Configure the worker via environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `PING_BATCH_SIZE` | Number of IPs to process per batch | `10` |
| `PING_CHECK_INTERVAL` | Seconds between checks for each IP | `60` |
| `PING_POLL_INTERVAL` | Seconds to sleep when no IPs are due | `5` |

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

## License

MIT
