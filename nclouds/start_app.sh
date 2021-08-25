#!/bin/bash

echo " === ENTRYPOINT SUMMARY ==="
echo " - RAILS_ENV: ${RAILS_ENV}"
echo " - START_UP: ${START_UP}"
echo " === END OF SUMMARY ==="

#echo "Debug container; just keep container running..."
#tail -f /dev/null

if [ "$RAILS_ENV" == "development" ]
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
  if [ -f /recognize/tmp/pids/server.pid ]; then
    rm /recognize/tmp/pids/server.pid
    echo "rm pid"
  fi
  # Start server
  if [ "$START_UP" == "ngrok" ]
  then
    # 1 version ngrok
    npm install ngrok
    ngrok http 50000 &
    sleep 3
    curl -s localhost:4040/api/tunnels
    bin/rails server --binding 0.0.0.0 --port 50000
  elif [ "$START_UP" == "ssl" ]
  then
    # 2 version ssl
    mkdir ~/.ssl
    openssl req -newkey rsa:2048 -nodes -keyout ~/.ssl/server.key -x509 -days 365 -out ~/.ssl/server.crt -subj "/C=US/ST=New York/L=Brooklyn/O=Recognize/CN=*.recognizeapp.com"
    bin/rails_ssl
  else
    bundle exec rails s
  fi
else
  bundle config set deployment 'true'                              
  bundle config set frozen 'true'                                  
  bundle config set no-cache 'true'                                
  bundle config set without 'development test build'    
  
  # get samples for credentials
  nclouds/use_samples.sh
  # get variables
  nclouds/use_node_script.sh "/recognize/$EnvironmentType/"
  source ssm_source
  # logs to cloudwatch
  RAILS_ENV=production bundle exec rails s puma
fi
