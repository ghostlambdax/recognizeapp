#!/bin/bash -e
set -e
# var to get return variables rom cluster services
# Deployment steps that need access to AWS credentials
# For deployment steps that need access to RDS, use start_deployment.sh
retval=""
retmsg="Deploy Complete:"

# use the latest version of ruby that is installed
# no matter what
# export RBENV_VERSION=$(rbenv global)

run_release() {
  local TASK_NAME=$1
  echo "`date` - updating image tag - $TASK_NAME"
  CONTAINER_DEFINITIONS=$(aws ecs describe-task-definition --task-definition $TASK_NAME --region $AWS_DEFAULT_REGION | jq ".taskDefinition.containerDefinitions")
  CONTAINER_VOLUMES=$(aws ecs describe-task-definition --task-definition $TASK_NAME --region $AWS_DEFAULT_REGION | jq ".taskDefinition.volumes")

  echo "`date` - replacement of container definitions rails"
  TARGET=$(echo $CONTAINER_DEFINITIONS | jq ".[].image" | grep rails)
  REPLACEMENT="\"$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/recognize_rails:${tag}_${COMMIT}_$BUILD\""
  CONTAINER_DEFINITIONS="${CONTAINER_DEFINITIONS/$TARGET/$REPLACEMENT}"

  echo "`date` - replacement of container definitions nginx"
  TARGET=$(echo $CONTAINER_DEFINITIONS | jq ".[].image" | grep nginx) || echo "no nginx image to replace"
  REPLACEMENT="\"$AWS_ACCOUNT_ID.dkr.ecr.$AWS_DEFAULT_REGION.amazonaws.com/recognize_nginx:${tag}_${COMMIT}_$BUILD\""
  CONTAINER_DEFINITIONS="${CONTAINER_DEFINITIONS/$TARGET/$REPLACEMENT}"

  # For Alpine
  # CONTAINER_DEFINITIONS="${CONTAINER_DEFINITIONS/bin\/ash/bin\/bash}"

  echo "`date` - update the service with new revision - $TASK_NAME - $TASK_ROLE_NAME"
  TASK_ARN=$(aws ecs register-task-definition --region $AWS_DEFAULT_REGION --family $TASK_NAME --container-definitions "$CONTAINER_DEFINITIONS" --volumes "$CONTAINER_VOLUMES" --task-role-arn "$TASK_ROLE_NAME" | jq --raw-output ".taskDefinition.taskDefinitionArn")

  echo "`date` - New task revision: $TASK_ARN"
}

ensure_log_group() {
  local LOG_GROUP=$1
  echo "`date` - Checking to see if log group exists - $LOG_GROUP"
  foundGroupName=$(aws logs describe-log-groups --log-group-name-prefix=$LOG_GROUP |jq '.logGroups[].logGroupName')
  echo "`date` - foundGroupName - [$foundGroupName]"
  if [[ $foundGroupName == "\"$LOG_GROUP\"" ]] 
  then
    echo "`date` - Log group: $LOG_GROUP exists, doing nothing"
  else
    echo "`date` - Log group: $LOG_GROUP does not exist, creating it..."
    echo $(aws logs create-log-group --log-group-name $LOG_GROUP --tags rEnv=$EnvironmentType)
    echo "`date` - Log group: $LOG_GROUP finished creating"
  fi
}
update_fargate_task_definition() {
  local TASK_NAME=$1
  local TASK_FAMILY=$1
  local TASK_LOG_GROUP=$2
  local TASK_LOG_STREAM_PREFIX=$2
  local CPU_UNITS=$3
  local MEM_UNITS=$4
  local COMMAND=$5

  ensure_log_group $TASK_LOG_GROUP

  echo "`date` - updating deployment image tag - $TASK_NAME"

  ECR_IMAGE="${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/recognize_rails:${tag}_${COMMIT}_$BUILD"
  echo "`date` - New image: $ECR_IMAGE"

  EFS_FILE_SYSTEM_ID=$(aws cloudformation describe-stacks --stack-name=recognize-$EnvironmentType --query "Stacks[0].Outputs[?OutputKey=='EFSPublic'].OutputValue" --output text)
  echo "`date` - Using EFS FS ID: $EFS_FILE_SYSTEM_ID"

  NEW_TASK_DEFINITION=$(sed -e "s|{{ECR_IMAGE}}|$ECR_IMAGE|" \
      -e "s|{{AWS_DEFAULT_REGION}}|$AWS_DEFAULT_REGION|" \
      -e "s|{{TASK_FAMILY}}|$TASK_FAMILY|" \
      -e "s|{{AWS_ACCOUNT_ID}}|$AWS_ACCOUNT_ID|" \
      -e "s|{{DataDogAPIKey}}|$DataDogAPIKey|" \
      -e "s|{{TASK_LOG_GROUP}}|$TASK_LOG_GROUP|" \
      -e "s|{{TASK_LOG_STREAM_PREFIX}}|$TASK_LOG_STREAM_PREFIX|" \
      -e "s|{{EFS_FILE_SYSTEM_ID}}|$EFS_FILE_SYSTEM_ID|" \
      -e "s|{{CPU_UNITS}}|$CPU_UNITS|" \
      -e "s|{{MEM_UNITS}}|$MEM_UNITS|" \
      -e "s|{{COMMAND}}|$COMMAND|" \
      -e "s|{{ENVIRONMENT_TYPE}}|$EnvironmentType|" ./infrastructure/json_templates/rails_fargate.json)
  echo "`date` - New task definition: $NEW_TASK_DEFINITION"

  NEW_TASK_INFO=$(aws ecs register-task-definition --region "$AWS_DEFAULT_REGION" --cli-input-json "$NEW_TASK_DEFINITION")
  NEW_REVISION=$(echo $NEW_TASK_INFO | jq '.taskDefinition.revision')  
  TASK_ARN=$(echo $NEW_TASK_INFO | jq --raw-output '.taskDefinition.taskDefinitionArn')
  echo "`date` - New task definition revision: $NEW_REVISION"
}

run_deployment() {
  update_fargate_task_definition recognize-$EnvironmentType-task-deployments-fargate deploy-$EnvironmentType-fargate 4096 8192 nclouds/start_deployment.sh


  vpcId=$(aws ec2 describe-vpcs --filters "Name=tag:aws:cloudformation:stack-name,Values=recognize-$EnvironmentType-VPC*" | jq -r '.Vpcs[].VpcId')
  subnets=$(aws ec2 describe-subnets --filters "Name=tag:aws:cloudformation:stack-name,Values=recognize-$EnvironmentType-VPC*" "Name=tag:Name,Values=*private*" | jq -r '.Subnets | map(.SubnetId) | join(",")')
  securityGroups=$(aws ec2 describe-security-groups --filters "Name=tag:aws:cloudformation:stack-name,Values=recognize-$EnvironmentType-ECSCluster*" | jq -r '.SecurityGroups | map(.GroupId) | join(",")')
  networkConfig="awsvpcConfiguration={subnets=[${subnets}],securityGroups=${securityGroups},assignPublicIp=DISABLED}"
  platformVersion="1.4.0"

  CURRENT_RELEASE_INFO="$PRBRANCH,${tag}_${COMMIT}_$BUILD,https://github.com/Recognize/recognize/pull/`echo $BRANCH | sed -e "s/PR\-//g"`"
  echo "`date` - run deployment script (assets compile and migrations) - $TASK_DEPLOY - $TASK_ARN"
  echo "`date` - network config: $networkConfig"
  DEPLOY=$(aws ecs run-task --launch-type FARGATE --cluster $CLUSTER_NAME --task-definition $TASK_ARN --network-configuration $networkConfig --region $AWS_DEFAULT_REGION --platform-version $platformVersion | jq --raw-output ".tasks[].taskArn")

  # try additional task just for asset precompilation, for now, dont care whether this finishes on time
  assetPrecompileOverrides='{"containerOverrides":[{"name":"recognize-rails","command":["/bin/bash","-c","echo start && echo `date` && apk add --no-cache nodejs npm && nclouds/use_samples.sh && nclouds/use_node_script.sh /recognize/$EnvironmentType/ && source ssm_source && echo setup done && echo `date` && bundle exec rake assets:precompile && echo assets:precompile done && RAILS_ENV=production RAILS_DEPLOY_SCRIPT=true bundle exec rake assets:non_digested && echo assets:non_digested done && echo echo `date`"]}]}'
  PRECOMPILE_DEPLOY_TASK=$(aws ecs run-task --overrides "$assetPrecompileOverrides" --launch-type FARGATE --cluster $CLUSTER_NAME --task-definition $TASK_ARN --network-configuration $networkConfig --group recognize-$EnvironmentType-task-deployments-fargate-precompile --region $AWS_DEFAULT_REGION --platform-version $platformVersion | jq --raw-output ".tasks[].taskArn")
  echo "`date` - Precompile task: $PRECOMPILE_DEPLOY_TASK"

  echo "`date` - Timeout to run assets and migrate - $CLUSTER_NAME - $DEPLOY"
  stackStatus=$(aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $DEPLOY --region $AWS_DEFAULT_REGION | jq --raw-output ".tasks[].lastStatus")
  NEXT_WAIT_TIME=0
  TIMEOUT=1800
  until [ $NEXT_WAIT_TIME -eq $TIMEOUT ] \
  || [ "$stackStatus" = "STOPPED" ]; do
    sleep 1s
    NEXT_WAIT_TIME=$((NEXT_WAIT_TIME + 1))
    stackStatus=$(aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $DEPLOY --region $AWS_DEFAULT_REGION | jq --raw-output ".tasks[].lastStatus")
    echo "`date` - deploying ($NEXT_WAIT_TIME / $TIMEOUT until timeout)....$stackStatus"
  done

  echo "`date` - get exit code for cluster $CLUSTER_NAME - $DEPLOY"
  exitCode=$(aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $DEPLOY --region $AWS_DEFAULT_REGION | jq --raw-output '.tasks[].containers[].exitCode')

  echo "CURRENT_RELEASE_INFO: $CURRENT_RELEASE_INFO"
  aws ssm put-parameter --overwrite --name "/recognize/$EnvironmentType/CURRENT_RELEASE_INFO" --type StringList --value $CURRENT_RELEASE_INFO

  if [ "$exitCode" == "0" ]
  then
    echo "`date` - :)"
    echo "Deployment task pass: $stackStatus exit code $exitCode for task $DEPLOY"
  else
    echo "`date` - :("
    echo "Deployment task failed: $stackStatus exit code $exitCode for task $DEPLOY"
    exit 1
  fi

  echo "`date` - Done."
}

# run_update_scheduled_tasks() {
#   echo "Running update scheduled tasks"
#   echo `pwd`
#   gem install whenever
#   bin/aws/sync_cron.rb $EnvironmentType
#   # bundle exec rails r "bin/aws/sync_cron.rb $EnvironmentType"
# }

run_queues() {
  echo "Starting run queues for ${tag}_${COMMIT}_$BUILD"
  local TASK_COUNT=$1

  # templateUrl="https://s3-us-west-1.amazonaws.com/recognize-everest-fargate/${EnvironmentType}/applications/recognize_delayjob-fargate.yaml"
  templateUrl="https://recognize-$EnvironmentType-infrastructure.s3-us-west-1.amazonaws.com/$EnvironmentType/applications/recognize_delayjob-fargate.yaml"
  data="$(aws ecs list-services --cluster $CLUSTER_NAME --region $AWS_DEFAULT_REGION)"
  aray=$(jq -c '.serviceArns[]' <<< $data)
  arr=$(echo $aray | tr " " "\n")
  i=0

  echo "templateUrl: $templateUrl"
  
  # assemble array of existing services so we can do a diff between those
  # and those declared in nclouds/queues file so we know which to shut down
  # and which to create/update
  declare -a values
  for x in $arr
  do
    if [[ $x == *'ecs-'*'/recognize' ]]; then continue; fi
    if [[ $x == *'DDService'* ]]; then continue; fi
    values[$i]=$(sed -e 's/^"//' -e 's/"$//' <<<"$x")
    i=$((i+1))
  done
  size=${#values[@]}
  if [[ $size == 0 ]]; then size=1; fi
  file="nclouds/queues"
  declare -a queue_data
  queue_size=0

  echo "templateUrl: $templateUrl"
  
  # For each queue that should be present
  while IFS= read line
  do
    echo "Managing queue: $line"
    for (( i=0; i<$size; ++i))
    do
      stackname=$(echo $line | sed 's/_//g')-$EnvironmentType-fargate
      # if existing service we are iterating on matches queue we should have
      # to update it

      if [[ ${values[$i]} == */$line-delayjob-fargate ]]; then
        echo "Updating service "$line"    "${values[$i]} +"   "$i
        aws cloudformation update-stack --stack-name $stackname --template-url $templateUrl --parameters ParameterKey=ContainerCPU,ParameterValue=1024 ParameterKey=ContainerMemory,ParameterValue=2048 ParameterKey=EnvironmentType,ParameterValue=$EnvironmentType ParameterKey=DataDogAPIKey,ParameterValue=$DataDogAPIKey ParameterKey=ImageTag,ParameterValue=${tag}_${COMMIT}_$BUILD ParameterKey=RailsECR,ParameterValue=recognize_rails ParameterKey=ServiceName,ParameterValue=$line ParameterKey=TaskCount,ParameterValue=$TASK_COUNT --capabilities CAPABILITY_NAMED_IAM || echo "No updates are to be performed."
        break
      else
        # Existing service doesn't match the queue in the file
        # Do nothing, unless we've reached the end of the existing services
        if [[ $i == $((size-1)) ]]; then
          # otherwise, if we've looped through all the existing services
          # and haven't found a match, this must be a new queue
          echo  "Creating service "$line"-delayjob-fargate"
          aws cloudformation create-stack --stack-name $stackname --template-url $templateUrl --parameters ParameterKey=EnvironmentType,ParameterValue=$EnvironmentType ParameterKey=DataDogAPIKey,ParameterValue=$DataDogAPIKey ParameterKey=ImageTag,ParameterValue=${tag}_${COMMIT}_$BUILD ParameterKey=RailsECR,ParameterValue=recognize_rails ParameterKey=ServiceName,ParameterValue=$line ParameterKey=TaskCount,ParameterValue=$TASK_COUNT --capabilities CAPABILITY_NAMED_IAM
          break
        fi
      fi
    done
    queue_data[$queue_size]=$line
    queue_size=$((queue_size+1))
  done <"$file"
  size_qd=${#queue_data[@]}

  # loop to wait on all the queues steady state
  file="nclouds/queues"
  declare -a queue_data
  queue_size=0

  # For each queue that should be present
  # while IFS= read line
  # do
  #   wait_until_service_steady_state $line-delayjob-fargate
  # done <"$file"

  # loop to clear out queues from CF
  # that are no longer needed (eg not specified in nclouds/queues)
  for (( outer =0 ; outer < $size ; ++outer))
  do
    for((inner=0 ; inner < $size_qd ; ++inner))
    do
    if [[ ${values[$outer]} == */${queue_data[$inner]}-delayjob-fargate ]]; then
      break
    else
     if [[ $inner == $((size_qd-1)) ]]; then
      service_arn=$( cut -d "/" -f 2 <<< ${values[$outer]})
      stack_name=$( cut -d "-" -f 1 <<< $service_arn)
      echo "`date` - removing stack $stack_name"
      stackname=$(echo $stack_name | sed 's/_//g')
      aws cloudformation delete-stack --stack-name $stackname #${values[$outer]}
     fi
    fi
    done
  done
}

ensure_deploy_container_instance() {
   ./infrastructure/ensure_deploy_container_instance.rb $1
}

wait_until_service_steady_state() {
  local SERVICE=$1
  echo "`date` - Waiting for steady state: $SERVICE"
  TIMEOUT=0 # 15 MIN
  lastStatus=""
  until [ $TIMEOUT -eq 1800 ] \
  || [[ $lastStatus == *"has reached a steady state"* ]]; do
    sleep 1s
    TIMEOUT=$((TIMEOUT + 1))
    numDeploys=$(aws ecs describe-services --cluster $CLUSTER_NAME --services $SERVICE |jq '.services[].deployments' |jq length)
    serviceStatus=$(aws ecs describe-services --service $SERVICE --region $AWS_DEFAULT_REGION --cluster $CLUSTER_NAME |jq ".services[] | .events[] | .message" |head -n1)
    # if [ "$lastStatus" != "$serviceStatus" ];
    if [ $numDeploys == 1 ] && [ "$lastStatus" != "$serviceStatus" ];
    then
      echo "`date` - Log: $serviceStatus"
      lastStatus=$serviceStatus
    fi
  done
  retval=""
  if [[ $lastStatus == *"has reached a steady state"* ]];
  then
    retmsg="$retmsg\nSuccessful deployment to cluster $CLUSTER_NAME with service $SERVICE"
    retval="true"
  else
    retmsg="$retmsg\nFailed deployment to cluster $CLUSTER_NAME with service $SERVICE."
    retval="false"
    # isSteady: error because it didn't deployed correctly.
  fi

  # aws sns publish --topic-arn $SNS --subject "$CLUSTER_NAME [$PRBRANCH]" --message "$lastStatus" --region $AWS_DEFAULT_REGION
}

wait_cfn_update_complete() {
  local stack="$1"
  local lastEvent
  local lastEventId
  local stackStatus=$(aws cloudformation describe-stacks --region $AWS_DEFAULT_REGION --stack-name $stack | jq -c -r .Stacks[0].StackStatus)

  until \
  [ "$stackStatus" = "CREATE_COMPLETE" ] \
  || [ "$stackStatus" = "CREATE_FAILED" ] \
  || [ "$stackStatus" = "DELETE_COMPLETE" ] \
  || [ "$stackStatus" = "DELETE_FAILED" ] \
  || [ "$stackStatus" = "ROLLBACK_COMPLETE" ] \
  || [ "$stackStatus" = "ROLLBACK_FAILED" ] \
  || [ "$stackStatus" = "UPDATE_COMPLETE" ] \
  || [ "$stackStatus" = "UPDATE_ROLLBACK_COMPLETE" ] \
  || [ "$stackStatus" = "UPDATE_ROLLBACK_FAILED" ]; do

    lastEvent=$(aws cloudformation describe-stack-events --region $AWS_DEFAULT_REGION --stack $stack --query 'StackEvents[].{ EventId: EventId, LogicalResourceId:LogicalResourceId, ResourceType:ResourceType, ResourceStatus:ResourceStatus, Timestamp: Timestamp }' --max-items 1 | jq .[0])
    eventId=$(echo "$lastEvent" | jq -r .EventId)
    if [ "$eventId" != "$lastEventId" ]
    then
      lastEventId=$eventId
      echo $(echo $lastEvent | jq -r '.Timestamp + "\t-\t" + .ResourceType + "\t-\t" + .LogicalResourceId + "\t-\t" + .ResourceStatus')
    fi
    sleep 3
    stackStatus=$(aws cloudformation describe-stacks --region $AWS_DEFAULT_REGION --stack-name $stack | jq -c -r .Stacks[0].StackStatus)
    echo 'In progress....'
  done

  echo "$stack Status: $stackStatus"

  if [[ "$stackStatus" != "CREATE_COMPLETE" ]] && [[ "$stackStatus" != "UPDATE_COMPLETE" ]];
  then
    echo "Stack update error for delayjob $stack"
    exit 1
  fi
}

wait_to_check_containers_images() {
  TaskRunning=$(aws ecs list-tasks --cluster $CLUSTER_NAME | jq --raw-output '.taskArns[]')
  TaskDefinitions=$(aws ecs describe-tasks --cluster $CLUSTER_NAME --tasks $TaskRunning | jq --raw-output '.tasks[].taskDefinitionArn')
  for task in $TaskDefinitions
  do
    if [[ $task != *"datadog"* ]]  && [[ $task != *"cron"* ]] && [[ $task != *"ecs-exec-demo"* ]];
    then
      echo $task
      tasktag=$(aws ecs describe-task-definition --task-definition $task | jq --raw-output '.taskDefinition.containerDefinitions[0].image | split("/")[-1] | split(":")[-1]')
      echo $tasktag "==" ${tag}_${COMMIT}_${BUILD}
      if [ "$tasktag" != "${tag}_${COMMIT}_${BUILD}" ]
      then
        echo "The service task definition is running an outdated docker image tag"
        exit 1
      fi
    fi
  done
}

# Fetch the DD key from Secrete manager
echo "Fetching DD Api key - will give error for environments that don't use DD"
DataDogAPIKey=$(aws secretsmanager get-secret-value --secret-id /recognize/${EnvironmentType}/DATADOG_API_KEY | jq --raw-output '.SecretString' | jq --raw-output ".[\"/recognize/${EnvironmentType}/DATADOG_API_KEY\"]")

echo "0. Starting Jenkins deployment for [$tag_$COMMIT_$BUILD]"
aws --version

echo "`date` - 1. Shut down DJ queues"
# CF templates to create/remove services with 0 task count
run_queues 0

echo "`date` - 1.5. Check there is an available container instance"
# # This is to make sure to spin up a new instance so that when the recognize service
# # goes to place a task, it doesn't have to wait for the capacity provider to spin up the instance
# # Ie, this is a performance optimization
ensure_deploy_container_instance $EnvironmentType

echo "`date` - 2. Run deployment script (migrations and deployment commands)"
aws sns publish --topic-arn $SNS --subject "$CLUSTER_NAME [$PRBRANCH]" --message "Starting deployment - $BUILD_URL" --region $AWS_DEFAULT_REGION
# Run ECS task in cluster for assets and migrations
run_deployment
# echo '`date` - 3. Setup all schedule task'
# # Run ruby script with whenever
# run_update_scheduled_tasks
echo '`date` - 4. Create new release of recognize service'
# Get task definition name
TASK_NAME=$(aws ecs describe-services --cluster $CLUSTER_NAME --services "recognize" --region $AWS_DEFAULT_REGION | jq --raw-output '.services[].taskDefinition | split("/")[-1] | split(":")[0]')
# Create new task definition revision
run_release $TASK_NAME
echo "`date` - 5. Create new deployment on service: recognize"
# Update task definition
aws ecs update-service --region $AWS_DEFAULT_REGION --cluster $CLUSTER_NAME --service "recognize" --task-definition $TASK_ARN
# Create new task definition for support container
run_release support-task-${EnvironmentType}
# Update task definition
aws ecs update-service --region $AWS_DEFAULT_REGION --cluster $CLUSTER_NAME --service "support" --task-definition $TASK_ARN
# Wait for service to fetch the changes
# sleep 30s
# Look for steady state
# wait_until_service_steady_state "recognize"
# Look for steady state
# wait_until_service_steady_state "support"
# Create new revision for cron task definition
update_fargate_task_definition "recognize-${EnvironmentType}-cron-fargate" "cron-${EnvironmentType}-fargate" 1024 2048 "echo croncmdshouldgetoverriden"
# echo '`date` - 6. Bring up DJ queues'
# CF templates to create/remove services with 1 task count
# run_queues 1
echo '`date` - 7. Deployment process alert check'
allDeploys=""
# Get all services from the cluster
# NOTE: temporarily disable waiting for steady state
# ECS_SERVICES=$(aws ecs list-services --cluster $CLUSTER_NAME --region $AWS_DEFAULT_REGION | jq --raw-output '[.serviceArns[] | split("/")[-1]] | @sh')
# # Iterate between each service
# for ECS_SERVICE in ${ECS_SERVICES[@]}; do
#   # Trim service name
#   SERVICE_NAME=$(echo $ECS_SERVICE | sed -e "s/'//g")
#   # Look for steady state
#   wait_until_service_steady_state $SERVICE_NAME 
#   # If return false
#   if [ "$retval" == "false" ];
#   then
#     # Mark the deployment as failure
#     allDeploys="false"
#     echo "$SERVICE_NAME is not steady"
#   fi
# done
wait_until_service_steady_state "recognize"
wait_until_service_steady_state "support"

# If return false
if [ "$retval" == "false" ];
then
  # Mark the deployment as failure
  allDeploys="false"
  echo "recognize service is not steady"
fi

wait_to_check_containers_images

aws sns publish --topic-arn $SNS --subject "$CLUSTER_NAME [$PRBRANCH]" --message "$retmsg" --region $AWS_DEFAULT_REGION

if [ "$allDeploys" == "false" ];
then
  # exit with errors
  echo "`date` - mark build as failure because deployment didn't get an steady state after 5 min"
  exit 1
fi
