#!/bin/bash
ParameterStorePrefix=$1

echo "Setting up cron for prefix $ParameterStorePrefix"
nclouds/use_samples.sh
nclouds/use_node_script.sh $ParameterStorePrefix
source ssm_source
echo "Finished setting up cron for prefix $ParameterStorePrefix"
