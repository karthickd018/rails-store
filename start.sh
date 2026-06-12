#!/bin/bash
set -e

bundle exec rails db:prepare

# Start nginx in background
nginx -g "daemon off;" &

# Start puma in foreground
exec bundle exec puma -C config/puma.rb