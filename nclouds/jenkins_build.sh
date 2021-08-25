#!/bin/bash -e
set -xe

# get samples for credentials
. ~/.bashrc
nclouds/use_samples.sh

awsversion=$(aws --version)
echo "AWS versios: $awsversion"
if [[ $awsversion =~ aws-cli.2* ]]
then
# aws cli v2
aws ecr get-login-password | docker login -u AWS ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com --password-stdin
else
aws ecr get-login --no-include-email --region ${AWS_DEFAULT_REGION} | awk '{printf $6}' | docker login -u AWS ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com --password-stdin
fi
# Mount EFS
# echo "EFS: Mounting..."
# # sudo mount -t efs -o tls fs-2113df38:/workspace/vendor ./vendor
# sudo mount -t efs -o tls fs-2113df38:/ /mnt/efs
# echo "EFS: Mounted..."

# set dummy variables for assets
export aws_aws_access_key_id=dummy
export aws_aws_secret_access_key=dummy

# Pull the latest builder image from remote repository
docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/recognize_builder:latest || true

# Only build the 'builder' stage, using pulled image as cache
echo "DOCKER: Building builder image"
docker build 															\
  --target builder 												\
  --cache-from ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/recognize_builder:latest 		\
  -t recognize_builder:latest  							\
  -f infrastructure/Dockerfile 						\
  "."

# Pull the latest runtime image from remote repository
# (This may or may not be worthwhile, depending on your exact image)
docker pull ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/recognize_rails:latest || true

# Don't specify target (build whole Dockerfile)
# Uses the just-built builder image and the pulled runtime image as cache
echo "DOCKER: Building Dockerfile"
docker build \
  --cache-from recognize_builder:latest \
  --cache-from ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/recognize_rails:latest \
  -t recognize_rails:${tag}_${COMMIT}_${BUILD} \
  -f infrastructure/Dockerfile \
  "."

echo "DOCKER: Building Dockerfile.nginx"
docker build -t recognize_nginx:${tag}_${COMMIT}_${BUILD} -f infrastructure/Dockerfile.nginx .

# Docker tag
echo "DOCKER: adding tags..."
echo "DOCKER: tagging recognize_builder: recognize_builder:${tag}_${COMMIT}_${BUILD} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/recognize_builder:${tag}_${COMMIT}_${BUILD}"
docker tag recognize_builder:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/recognize_builder:latest
docker tag recognize_builder:latest ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/recognize_builder:${tag}_${COMMIT}_${BUILD}

echo "DOCKER: tagging recognize_rails: recognize_rails:${tag}_${COMMIT}_${BUILD} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/recognize_rails:${tag}_${COMMIT}_${BUILD}"
docker tag recognize_rails:${tag}_${COMMIT}_${BUILD} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/recognize_rails:${tag}_${COMMIT}_${BUILD}
docker tag recognize_rails:${tag}_${COMMIT}_${BUILD} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/recognize_rails:latest

echo "DOCKER: tagging recognize_nginx: recognize_nginx:${tag}_${COMMIT}_${BUILD} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/recognize_nginx:${tag}_${COMMIT}_${BUILD}"
docker tag recognize_nginx:${tag}_${COMMIT}_${BUILD} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/recognize_nginx:${tag}_${COMMIT}_${BUILD}
docker tag recognize_nginx:${tag}_${COMMIT}_${BUILD} ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/recognize_nginx:latest
echo "DOCKER: tagged containers"

# Push to ECR
echo "DOCKER: pushing to ECR"
echo "DOCKER: pushing recognize_builder"
# docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/recognize_builder:${tag}_${COMMIT}_${BUILD}
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/recognize_builder:latest

echo "DOCKER: pushing recognize_rails"
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/recognize_rails:${tag}_${COMMIT}_${BUILD}
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/recognize_rails:latest

echo "DOCKER: pushing recognize_nginx"
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/recognize_nginx:${tag}_${COMMIT}_${BUILD}
docker push ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/recognize_nginx:latest

# Cleanup
echo "DOCKER: cleaning up"
{
	docker rm -f $(docker ps -aq)
} || {
	exit 0
}
{
	docker rmi -f $(docker images -aq)
} || {
	exit 0
}
{
	docker volume prune -f
} || {
	exit 0
}
