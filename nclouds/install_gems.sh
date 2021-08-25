#!/bin/bash -e
set -e
# set job from CI command
REFRESH_CACHE="$1"
INSTALL="$2"
# check ruby
if [[ $(head -n 2 Gemfile) =~ ([[:digit:]].[[:digit:]].[[:digit:]](-p[[:digit:]]+)?) ]]; then ([[ $(rbenv versions |grep ${BASH_REMATCH[1]}) =~ ([[:digit:]].[[:digit:]].[[:digit:]](-p[[:digit:]]+)?) ]] && echo 'Found installed ruby, no need to install' )|| (echo 'Need to install' && bash nclouds/ruby-setup-jenkins.sh ${BASH_REMATCH[1]}); else echo "Unable to parse ruby version from Gemfile"; fi
# check version of ruby
if [[ $(head -n 2 Gemfile) =~ ([[:digit:]].[[:digit:]].[[:digit:]](-p[[:digit:]]+)?) ]]; then echo "Setting rbenv to version ${BASH_REMATCH[1]}" && rbenv local ${BASH_REMATCH[1]}; else echo "Unable to parse ruby version from Gemfile"; fi
RUBY_VERSION=${BASH_REMATCH[1]}

# install gems
if [ "${REFRESH_CACHE}" == "false" ] && [ "${INSTALL}" == "false" ];
then
  echo "fetch cache"
  aws s3 cp s3://recognize-jenkins-cache/jenkins/${RUBY_VERSION}/cache cache
  if [ -e cache ];
  then
    echo "bundle cache found"
    {
      tar -pxzf cache
      rm -Rf cache
    } || {
      echo "cache corrupted, generating gems"
    }
  fi
fi
if [ "${INSTALL}" == "false" ];
then
  bundle package --all
  tar -pczf cache vendor/cache
  aws s3 cp cache s3://recognize-jenkins-cache/jenkins/${RUBY_VERSION}/cache
  rm -Rf cache
elif [ "${INSTALL}" == "true" ];
then
  bundle install --deployment --path vendor/bundle -j6
fi
