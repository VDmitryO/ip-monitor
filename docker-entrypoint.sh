#!/bin/bash
set -e

echo "Running database migrations..."
bundle exec rake db:migrate

echo "Starting application..."
exec "$@"
