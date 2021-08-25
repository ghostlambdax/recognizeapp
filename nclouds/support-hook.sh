#!/bin/bash
# This script provides a hook for additional services/features needed by support.

_SNAME="${1}"
_PKGS[0]="tmux"
_PKGS[1]="less"
_PKGS[2]="xz"      # needed for compressing exports for download.
_PKGS[3]="gnupg"   # needed for BR decrypting.

echo "- launched with SNAME: [${_SNAME}]"

function install_packages() {
  for p in ${_PKGS[@]}; do
    echo "  - checking for: ${p}"
    apk -e info ${p}
    if [ $? == 1 ] ; then
      echo "    - not found, installing..."
      apk add --no-cache ${p}
    else
      echo "    - found"
    fi
  done
}

echo "- install packages..."
install_packages

# source the ssm_source file to get env setup properly.
echo "setting up env..."
source ssm_source

# set ruby shell pager to nil.
echo "- setting ruby shell pager to nil..."
echo "Pry.pager = nil" >.pryrc

# add aliases if they dont exist.
touch ~/.profile
# bxr
grep -qxF "alias bxr='bundle exec rails c -e production'" ~/.profile || echo "alias bxr='bundle exec rails c -e production'" >> ~/.profile
# ll
grep -qxF "alias ll='ls -lAh'" ~/.profile || echo "alias ll='ls -lAh'" >> ~/.profile
# brh (bulk recognition helper)
grep -qxF "alias brh='ruby bin/support/bulk_recognize_helper.rb'" ~/.profile || echo "alias brh='ruby bin/support/bulk_recognize_helper.rb'" >> ~/.profile

# start tmux.
echo "- launching tmux session..."
tmux new-session -A -s $_SNAME
