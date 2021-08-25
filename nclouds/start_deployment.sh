#!/bin/bash -e
# pip python-dev and awscli is for sync assets on s3 bucket of cdn
# Deployment steps that need access to RDS
# For deployment steps that need access to AWS credentials, use jenkins_deployment.sh

apk add --no-cache aws-cli
apk add --no-cache nodejs npm

# get samples for credentials
apk add --no-cache rsync
nclouds/use_samples.sh
# get variables
nclouds/use_node_script.sh "/recognize/$EnvironmentType/"
source ssm_source

./infrastructure/ensure_deploy_container_instance.rb $EnvironmentType

# NOTE: This is old. Precompile is now a separate Fargate task in the run_deployment method of jenkins_deployment.sh
# (I think...)
# compile assets - move assets to efs
# RAILS_ENV=production RAILS_DEPLOY_SCRIPT=true bundle exec rake assets:precompile --trace 2>&1 | sed -e 's/^/PRECOMPILING: /;' &
# (RAILS_ENV=production RAILS_DEPLOY_SCRIPT=true bundle exec rake assets:precompile --trace && rsync -va --ignore-existing /usr/src/app/tmp/assets/ /usr/src/app/public/assets/ ) 2>&1 | sed -e 's/^/PRECOMPILING: /;' &

# compile non-digested assets
# ex. Favicon and ajax-loader-company.gif
# RAILS_ENV=production RAILS_DEPLOY_SCRIPT=true bundle exec rake assets:non_digested

# compile themes
RAILS_ENV=production RAILS_DEPLOY_SCRIPT=true bundle exec rake recognize:compile_themes --trace 2>&1 | sed -e 's/^/THEMECOMPILATION: /;' &

PATH="$(gem env gemdir)/bin:$PATH"
bin/aws/sync_cron.rb $EnvironmentType 2>&1 | sed -e 's/^/CRONSYNC: /;' &

echo "debug release info"
echo $CURRENT_RELEASE_INFO

echo "debug EFS start"
df -h
echo "debug EFS end"
# rsync files from stashed public directory back into new public dir which is EFS
rsync -azh --stats /usr/src/app/public-orig/ /usr/src/app/public 2>&1 | sed -e 's/^/RSYNC: /;' &

# refresh CMS cache
# Just using sales queue because its mostly unused
RAILS_ENV=production bundle exec rails r 'CmsManager.delay(queue: "sales").reset_page_caches' 2>&1 | sed -e 's/^/CMSCACHERESET: /;' &

# run migrations
echo "Starting database migrations in process"
RAILS_ENV=production bundle exec rake db:migrate --trace

# trim db sessions
echo "Starting database session trim in process"
RAILS_ENV=production bundle exec rake db:sessions:trim

echo "start_deployment.sh has reached the end - waiting for background processes to finish"
wait # for bg processes to finish

# successful termination
exit 0
