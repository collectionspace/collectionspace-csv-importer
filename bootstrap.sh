#!/bin/bash

CACHE_FILE=tmp/caching-dev.txt

if [ -z "$CBI_DB_PORT" ]; then
  CBI_DB_PORT=5432
  echo "Using default DB PostgreSQL port 5432"
else
  echo "Using custom DB PostgreSQL port $CBI_DB_PORT"
fi

docker stop postgres && docker rm -f postgres || true
docker stop redis && docker rm -f redis || true

docker run --name postgres -e POSTGRES_PASSWORD=postgres -d -p $CBI_DB_PORT:5432 postgres:12
docker run --name redis -d -p 6379:6379 redis:6

sleep 1

if [ -f "$CACHE_FILE" ]; then
  echo "Dev cache is already enabled."
else
  ./bin/rails dev:cache
fi

./bin/rails db:setup
