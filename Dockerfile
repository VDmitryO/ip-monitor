FROM ruby:3.4.7-slim

RUN apt-get update -qq && \
    apt-get install -y build-essential libpq-dev && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock* ./
RUN bundle install

COPY . .

# Make entrypoint scripts executable
RUN chmod +x docker-entrypoint.sh docker-test-entrypoint.sh

EXPOSE 9292

ENTRYPOINT ["./docker-entrypoint.sh"]
CMD ["bundle", "exec", "puma", "config.ru", "-p", "9292", "-b", "tcp://0.0.0.0"]
