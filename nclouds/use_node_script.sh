#!/bin/bash
# Script to fetch variables from AWS SSM Parameter Store
# fist args: 'ssm_source' name of file with all the exports variables
# second args: '.env' name of the file with all definitons of variables
# third args: $1 hierarchy of parameters. i.e. /recognize/staging /jenkis/production
# fourth args: $AWS_DEFAULT_REGION region from which fetch the variables.

if [ -f ssm_source ]; then
  echo "ssm_source already created"
  exit 1
fi
echo 'Starting use_node_script.sh'
# npm install aws-sdk
# nodejs nclouds/ssm_get_parameters.js 'ssm_source' '.env' $1 $AWS_DEFAULT_REGION
ruby infrastructure/set_env.rb $1 'ssm_source'
echo 'Completed use_node_script.sh'
