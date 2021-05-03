#!/bin/bash

if [[ -z "${SIDEKIQ_ENABLED}" ]]; then
  ./bin/rails assets:precompile
  ./bin/rails db:create
  ./bin/rails db:migrate
  ./bin/rails db:seed
fi
exec "$@"
