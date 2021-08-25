# Create AMI For test

+ Install dependencies:
```
$ sudo apt update
$ curl -sL https://deb.nodesource.com/setup_8.x | sudo bash -
$ sudo apt-get install -y libssl-dev libreadline-dev zlib1g-dev build-essential libssl-dev libreadline-dev zlib1g-dev python3-distutils nodejs unzip libnss3 openjdk-8-jre-headless xvfb libgconf-2-4 jq
$ sudo apt -y install libmysqlclient-dev imagemagick
$ sudo apt install -y mysql-server
$ sudo apt install -y redis
```
+ Install rbenv and ruby:
```
$ git clone https://github.com/rbenv/rbenv.git ~/.rbenv
$ git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
$ curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-doctor | bash
$ cd ~/.rbenv && src/configure && make -C src
$ export PATH="/home/ubuntu/.rbenv/plugins/ruby-build/bin:/home/ubuntu/.rbenv/bin:/home/ubuntu/.local/bin:$PATH"
$ eval "$(rbenv init -)"
$ cd
```
+ Add in the first lines of ~/.bashrc
```
$ vim ~/.bashrc
# in the first lines add
export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$HOME/.rbenv/bin:$HOME/.local/bin:$PATH"
eval "$(rbenv init -)"
$ . .bashrc
```
+ Install version of ruby:
```
$ rbenv install 2.5.1
$ rbenv global 2.5.1
$ gem update --system 2.6.14 --no-ri --no-rdoc
$ gem install bundler -v 1.16.1 --no-ri --no-rdoc
```
+ Install chromedriver and chrome:
  + Install Chromedriver
```
$ export DRV_VER=2.44
$ wget https://chromedriver.storage.googleapis.com/$DRV_VER/chromedriver_linux64.zip
$ unzip chromedriver_linux64.zip
$ sudo mv chromedriver /usr/local/bin/
$ chown ubuntu:ubuntu /usr/local/bin/chromedriver
$ chromedriver --version
```
  + Install Chrome
```
$ curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
$ sudo su
# echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list
# exit
$ sudo apt-get -y update
$ sudo apt-get -y install google-chrome-stable
```
+ Configure Mysql:
```
$ sudo mysql
mysql> GRANT ALL PRIVILEGES ON *.* TO 'jenkins'@'localhost' IDENTIFIED BY 'jenkinsroot';
mysql> \q
```
+ Install pip, awscli and httpie:
```
$ curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
$ sudo python3 get-pip.py
$ sudo pip install awscli
$ sudo pip install httpie==0.9.8
```
+ http Stubbed
```
sudo su
echo "echo 'Stubbed http command, ignoring...'" | cat > /usr/bin/http && chmod +x /usr/bin/http
exit
```
+ install docker
```
$ sudo apt-get update
$ sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
$ sudo apt-key fingerprint 0EBFCD88
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
$ sudo apt-get update
$ sudo apt-get install docker-ce docker-ce-cli containerd.io
$ sudo usermod -aG docker $USER    
```
