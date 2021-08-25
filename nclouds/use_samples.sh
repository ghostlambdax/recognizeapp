#!/bin/bash
# Script to override files and values will be replace by parameters from
# aws ssm parameter store
#   local.yml
#   database.yml
#   credentials.yml
#   newrelic.yml
# Also remove pid from files if is present.

cp config/local.yml.sample config/local.yml
echo "OVERRIDE local.yml with local.yml.sample"
cp config/database.yml.sample config/database.yml
echo "OVERRIDE database.yml with database.yml.sample"
cp config/credentials.yml.sample config/credentials.yml
echo "OVERRIDE credentials.yml with credentials.yml.sample"
cp config/newrelic.yml.sample config/newrelic.yml
echo "OVERRIDE newrelic.yml with newrelic.yml.sample"
if [ -f /recognize/tmp/pids/server.pid ]; then
  rm /recognize/tmp/pids/server.pid
  echo "rm pid"
fi
