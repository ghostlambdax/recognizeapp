#!/bin/bash
exit_script() {
  echo "Sends SIGTERM to child/sub processes"
  kill -TERM "$child"
}

trap exit_script SIGINT SIGTERM SIGHUP

if [ "$RAILS_ENV" == "development" ] || [ "$RAILS_ENV" == "test" ]
then
  # Set up environment (this should be on SSM Parameter Store)
  if [ ! -f config/local.yml ]; then
    cp config/local.yml.sample config/local.yml
    echo "using sample local"
  fi
  if [ ! -f config/database.yml ]; then
    cp config/database.yml.sample config/database.yml
    echo "using sample database"
  fi
  if [ ! -f config/credentials.yml ]; then
    cp config/credentials.yml.sample config/credentials.yml
    echo "using sample credentials"
  fi
  if [ ! -f config/newrelic.yml ]; then
    cp config/newrelic.yml.sample config/newrelic.yml
    echo "using sample newrelic"
  fi
  # Initial set up
  sleep 50
  RAILS_ENV=$RAILS_ENV bundle exec rake recognize:init --trace
else
  # get samples for credentials
  nclouds/use_samples.sh
  # get variables
  nclouds/use_node_script.sh "/recognize/$EnvironmentType/"
  source ssm_source
  if [ "$QUEUE_NAME" == "" ]
  then
    RAILS_ENV=production bundle exec rake db:migrate --trace #must be on deployment in jenkins.
  else
    if [ "$QUEUE_NAME" == "*" ]
    then
      RAILS_ENV=production bundle exec rake jobs:work &
      child=$!
    else
      RAILS_ENV=production QUEUE=${QUEUE_NAME} bundle exec rake jobs:work &
      child=$!
    fi
  fi
fi
echo "Queue started ${QUEUE_NAME} PID $$ - Queue - $child"
wait "$child"
echo "Exiting start_delayedjobs.sh PID $$ - Queue - $child"
wait "$child"
echo "Gracefully exited"
