#!/bin/bash -e
set -e
# set job from CI command
JOB="$1"
nclouds/use_node_script.sh "/jenkins/test/"
source ssm_source
. ~/.bashrc

# use samples
nclouds/use_samples.sh
cp config/credentials.yml.jenkins config/credentials.yml

# fetch chrome browser & driver from a custom repo
git clone https://github.com/TwilightCoder/chrome-binaries.git

# install chomedriver - BEGIN
# from official repo
#export DRV_VER=81.0.4044.69
#wget https://chromedriver.storage.googleapis.com/$DRV_VER/chromedriver_linux64.zip
#unzip chromedriver_linux64.zip

# from custom repo
# # unzip chrome-binaries/v81/chromedriver_linux64_v81.zip
# # sudo mv chromedriver /usr/local/bin/
# # chown ubuntu:ubuntu /usr/local/bin/chromedriver
# # chromedriver --version
# install chomedriver - END

# update signatures
# # curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -

# TESTING - wait until the dpkg frontend lock is released, for the following apt-get update
# # while sudo fuser /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock /var/lib/dpkg/lock-frontend >/dev/null 2>&1;
# # do
# #   ((__lmt++)) && ((__lmt==21)) && echo 'wait for dpkg/apt locks exhausted...' && break
# #   echo "Waiting for release of dpkg/apt locks (attempt $__lmt)";
# #   sleep 10
# # done
# wait end

# install chrome - BEGIN
# # sudo su

# latest version
#sudo apt-get -y update
#sudo apt-get -y install google-chrome-stable

# locked version from file (v81.0.4044.129)
# # sudo dpkg -i chrome-binaries/v81/google-chrome-stable_amd64_v81.deb
# sudo apt-get install -f # fix errors due to missing dependencies


google-chrome-stable --version
# install chrome - END


# set up database
# RAILS_ENV=test bundle exec rake recognize:init --trace
RAILS_ENV=test bundle exec rake parallel:rake[recognize:init]
