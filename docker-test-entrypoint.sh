#!/bin/bash
set -e

echo "Creating test database..."
bundle exec rake db:create

echo "Running database migrations..."
bundle exec rake db:migrate

echo "Running tests..."
exec "$@"
