#!/bin/bash

if [ "$DB_MIGRATE" = true ]; then
  ./bin/rails db:create
  ./bin/rails db:migrate
  ./bin/rails db:seed
fi

exec "$@"
