#!/bin/bash

_USER="${USER}"
# How to use this script:
# A) You need to configure your ssh connection
# https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-getting-started-enable-ssh-connections.html
# B) You need to give three parameters:
#   1. Environment where you need to connect.
#     Only options are patagonia|staging|production
#   2. AWS Profile where you configure your Keys.
#     https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html#cli-quick-configuration
#   3. Location where you have the Pem key of the Environment.
#     Only options are
#     */recognize_patagonia.pem|*/recognize_staging.pem|*/recognize_production.pem
# REQUIREMENTS
#   - AWS CLI (installed and setup)
#     + NOTE: you need the [session-manager-plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html#install-plugin-debian) installed as well
#   - jq
#   - bash 4+

# Execution:
# $ ./support-container.sh patagonia rec ~/path/to/recognize_patagonia.pem
# Exit:
# ctrl + A + D

AWS_DEFAULT_REGION="us-west-1"
EnvironmentType=${1}
AWS_PROFILE=${2}
PemKey=${3}
Command=${4}
: ${VERBOSE:=0}                                                         # set envvar 'VERBOSE=0' to enable verbose output of this script (0 turns verbose off, 1 is slightly more verbose 9 is show all messages)

function usage() {
  echo "Usage: $(basename ${0}) EnvironmentType AWS_PROFILE PemKey Command"
  echo " - EnvironmentType: [patagonia|staging|production]"
  echo " - AWS_PROFILE: AWS Profile to use (typically use 'rec')"
  echo " - PemKey: full path to .pem key for SSH logon to environment"
  echo " - Command: startup command to execute"
  echo "    - no-mp: no multiplexer session with ssm_source activated"
  echo "    - {empty}: multiplexer session with ssm_source activated"
  echo " Environment Variables:"
  echo "  - VERBOSE: [0-9] set script verbosity, 0 is least verbose 9 is most verbose"
  echo " Examples:"
  echo "  - prod shell with multiplexer: ./nclouds/support-container.sh production rec /path/to/your/recognize_production.pem"
  echo "  - prod shell with no multiplexer: ./nclouds/support-container.sh production rec /path/to/your/recognize_production.pem no-mp"
  echo ""
  exit 0
}

[ "${EnvironmentType}" == "-h" ] && usage
[ "${EnvironmentType}" == "" ] && echo -e "Script Error: No EnvironmentType supplied.\n" && usage
[ "${AWS_PROFILE}" == "" ] && echo -e "Script Error: No AWS_PROFILE supplied.\n" && usage
[ "${PemKey}" == "" ] && echo -e "Script Error: No PemKey supplied.\n" && usage
[ "${VERBOSE}" -gt 0 ] && echo "Checking information with AWS: EnvironmentType=${EnvironmentType}, AWS_PROFILE=${AWS_PROFILE}..."
[ "${VERBOSE}" -gt 8 ] && echo -e "PemKey=${PemKey}, contents:\n$(cat ${PemKey})\n\n"
ContainerInstances=$(aws ecs list-container-instances --cluster ecs-${EnvironmentType} --profile ${AWS_PROFILE} | jq --raw-output '.containerInstanceArns[]')
if [ "${ContainerInstances}" = "" ]; then
  echo "Error-200: No containers found, cannot continue."
  exit 200
fi
for instance in ${ContainerInstances}
do
  [ "${VERBOSE}" -gt 8 ] && echo " - checking instance: ${instance}"
  ContainerInstance=$(aws ecs describe-container-instances --container-instances ${instance} --cluster ecs-${EnvironmentType} --profile ${AWS_PROFILE})
  [ "${VERBOSE}" -gt 8 ] && echo "   - container instance is: ${ContainerInstance}"
  id=$(echo $ContainerInstance | jq --raw-output '.containerInstances[].ec2InstanceId')
  [ "${VERBOSE}" -gt 0 ] && echo " - instance id: ${id}"
  attributes=$(echo $ContainerInstance | jq --raw-output '.containerInstances[].attributes[]')
  [ "${VERBOSE}" -gt 8 ] && echo " - attributes: ${attributes}"
  if [[ $attributes == *"ec2_type"*"support"* ]];
  then
    [ "${VERBOSE}" -gt 0 ] && echo "  - found support container, getting dockerID..."
    dockerID=$(ssh -i ${PemKey} ec2-user@${id} sudo docker ps -q --filter="name=ecs-support-task*")
    if [ "${dockerID}" == "" ]; then
      echo "Error-201: no dockerID found, cannot continue."
      exit 201
    fi
    [ "${VERBOSE}" -gt 0 ] && echo "  - dockerID is: ${dockerID}, setting up config files..."
    ssh -t -i ${PemKey} ec2-user@${id} sudo docker exec -it ${dockerID} nclouds/use_samples.sh
    [ "${VERBOSE}" -gt 0 ] && echo "Setting up env"
    ssh -t -i ${PemKey} ec2-user@${id} sudo docker exec -it ${dockerID} nclouds/use_node_script.sh "/recognize/${EnvironmentType}/" ${AWS_DEFAULT_REGION}
    [ "${VERBOSE}" -gt 0 ] && echo "Setup Complete"

    case "${Command}" in
      "-h")
        usage
        ;;
      "no-mp")
        echo "Starting basic shell session (no multiplexer)..."
        ssh -t -i ${PemKey} ec2-user@${id} sudo docker exec -it ${dockerID} bash --rcfile ssm_source
        ;;
      *)
        echo "Starting multiplexer based session..."
        ssh -t -i ${PemKey} ec2-user@${id} sudo docker exec -it ${dockerID} /bin/bash -c "'/usr/src/app/nclouds/support-hook.sh ${_USER}'"
        ;;
    esac

    break
  fi
done
