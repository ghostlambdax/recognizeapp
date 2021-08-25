#! /usr/bin/env bash

. ~/.bashrc

ruby_version=${1:-"2.3.1"}
gem_version=${2:-"2.6.14"}
ruby_archive="$ruby_version.tar.gz"
ruby_install_path="/home/ubuntu/.rbenv/versions/$ruby_version"

echo "*****************************************"
echo "Setting up Ruby $ruby_version"
echo "*****************************************"

if ! [ -d $ruby_install_path ]; then
  if ! [ -e $SEMAPHORE_CACHE_DIR/$ruby_archive ]; then
    cd /home/ubuntu/.rbenv/plugins/ruby-build && git pull && cd -
    CFLAGS='-fPIC' rbenv install $ruby_version
    (cd $SEMAPHORE_CACHE_DIR && tar -cf $ruby_archive -C $ruby_install_path .)
  else
    echo "Ruby $ruby_version installation archive found in cache. Unpacking..."
    (cd $SEMAPHORE_CACHE_DIR && mkdir $ruby_install_path && tar xf $ruby_archive -C $ruby_install_path)
  fi
else
  echo "Ruby $ruby_version already installed. Skipping setup..."
fi

echo "Activating Ruby $ruby_version"
rbenv global $ruby_version

if ! [ $gem_version = "$(gem --version)" ]; then
  echo "Updating RubyGems to version $gem_version"
  gem update --system $gem_version --no-ri --no-rdoc
fi

echo "Installing bundler..."
gem install bundler --no-ri --no-rdoc

echo "Setup complete."
echo "-----------------------------------------------"
echo "Details:"
echo "$(ruby --version)"
echo "$(bundle --version)"
echo "RubyGems version: $(gem --version)"
