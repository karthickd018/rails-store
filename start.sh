#!/bin/bash
set -e

bundle exec rails db:prepare

echo "Preparing CloudWatch Agent..."

mkdir -p \
  /opt/aws/amazon-cloudwatch-agent/logs \
  /opt/aws/amazon-cloudwatch-agent/logs/state

/opt/aws/amazon-cloudwatch-agent/bin/config-translator \
  -input /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json \
  -input-dir /opt/aws/amazon-cloudwatch-agent/etc \
  -output /tmp/cwagent.toml

if [ -f /tmp/cwagent.toml ]; then
  echo "Starting CloudWatch Agent..."

  /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent \
    -config /tmp/cwagent.toml &
else
  echo "CloudWatch Agent config generation failed"
fi

# Start nginx in background
nginx -g "daemon off;" &

# Start puma in foreground
exec bundle exec puma -C config/puma.rb