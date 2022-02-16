#!/bin/bash

PUMA_WORKERS=1 RAILS_MAX_THREADS=1 bundle exec rdebug-ide --host 0.0.0.0 --port 1234 --dispatcher-port 1234 -- bin/rails s -p 3000 -b 0.0.0.0
