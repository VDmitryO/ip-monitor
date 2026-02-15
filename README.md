# IP Monitor API

A RESTful API service for monitoring IP addresses with automated ping checks and comprehensive statistics. Built with Grape, Sequel, and PostgreSQL, it provides real-time network monitoring capabilities with support for both IPv4 and IPv6 addresses.

## Features

- **IP Address Management**: Add, enable/disable, and delete IP addresses for monitoring
- **Automated Ping Monitoring**: Background workers continuously ping registered IPs at configurable intervals
- **Comprehensive Statistics**: Track RTT (round-trip time), packet loss, and statistical metrics (avg, min, max, median, stddev)
- **Scalable Architecture**: Support for multiple parallel workers with PostgreSQL-based locking
- **IPv4 & IPv6 Support**: Full support for both IP address formats
- **RESTful API**: Clean, well-documented API endpoints for easy integration

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

## API

All API endpoints are available at `http://localhost:9292/v1`

### POST /ips

Add a new IP address for monitoring.

**Request Body:**
```json
{
  "ip": "8.8.8.8",           // Required: IPv4 or IPv6 address
  "enabled": true            // Optional: Enable stats collection (default: true)
}
```

**Response (201 Created):**
```json
{
  "id": 1,
  "address": "8.8.8.8",
  "enabled": true,
  "next_check_at": "2026-02-15T13:00:00Z",
  "created_at": "2026-02-15T13:00:00Z",
  "updated_at": "2026-02-15T13:00:00Z"
}
```

### POST /ips/:id/enable

Enable statistics collection for an IP address. The ping worker will start monitoring this IP.

**Response (201 Created):**
```json
{
  "id": 1,
  "address": "8.8.8.8",
  "enabled": true,
  "next_check_at": "2026-02-15T13:00:00Z",
  "created_at": "2026-02-15T13:00:00Z",
  "updated_at": "2026-02-15T13:00:00Z"
}
```

### POST /ips/:id/disable

Disable statistics collection for an IP address. The ping worker will stop monitoring this IP.

**Response (201 Created):**
```json
{
  "id": 1,
  "address": "8.8.8.8",
  "enabled": false,
  "next_check_at": "2026-02-15T13:00:00Z",
  "created_at": "2026-02-15T13:00:00Z",
  "updated_at": "2026-02-15T13:00:00Z"
}
```

### GET /ips/:id/stats

Get ping statistics for an IP address within a time range.

**Query Parameters:**
- `time_from` (required): Start of time range (ISO 8601 datetime)
- `time_to` (required): End of time range (ISO 8601 datetime)

**Example Request:**
```
GET /ips/1/stats?time_from=2026-02-15T12:00:00Z&time_to=2026-02-15T13:00:00Z
```

**Response (200 OK):**
```json
{
  "avg_rtt": 25.43,          // Average round-trip time in milliseconds
  "min_rtt": 18.20,          // Minimum RTT
  "max_rtt": 45.67,          // Maximum RTT
  "median_rtt": 24.10,       // Median RTT
  "stddev_rtt": 5.32,        // Standard deviation of RTT
  "packet_loss_pct": 2.50,   // Packet loss percentage
  "total_checks": 60         // Total number of ping checks
}
```

**Error Response (422 Unprocessable Entity):**
```json
{
  "error": "No ping checks found for this IP in the given time range"
}
```

### DELETE /ips/:id

Delete an IP address and all its associated ping statistics.

**Response:** 204 No Content

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
