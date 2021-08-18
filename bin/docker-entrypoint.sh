#!/bin/bash
set -e

# wait database
until psql postgresql://postgres:postgres@postgres_db:5432 -c '\q'; do
  >&2 echo "Postgres is unavailable - sleeping"
  sleep 1
done

bundle exec rake db:create
bundle exec rake db:migrate

bundle exec ruby bin/run_worker.rb start
bundle exec ruby bin/run_server.rb


