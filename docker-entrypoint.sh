#!/bin/bash

./bin/rails assets:precompile
exec "$@"
