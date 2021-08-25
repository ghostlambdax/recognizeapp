#!/bin/bash -e
export JOB="$1"
echo "Calling start_test.sh $1"

# set test variables
source ssm_source
. ~/.bashrc
# Run test
#RAILS_ENV=test bundle exec bin/rspec_job $JOB
 KNAPSACK_GENERATE_REPORT=true RAILS_ENV=test bundle exec bin/rspec_job $JOB
