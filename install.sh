#!/bin/sh
#
# Install script based on https://github.com/siyelo/laptop/blob/master/install.sh
#
# This script bootstraps our OSX laptop to a point where we can run
# Ansible on localhost. It;
#  1. Installs
#    - xcode
#    - brew
#    - ansible
#    - ansible roles
#  2. Kicks off the ansible playbook
#    - ansible/playbook.yml
#
# It will ask you for your sudo password

install_user="${USER}"
laptop_repo="https://github.com/imjoshholloway/laptop.git"

fancy_echo() {
  local fmt="$1"; shift

  # shellcheck disable=SC2059
  printf "\n$fmt\n" "$@"
}

fancy_echo "Boostrapping ..."

trap 'ret=$?; test $ret -ne 0 && printf "failed\n\n" >&2; exit $ret' EXIT

set -e

# Ensure Apple's command line tools are installed
if ! command -v cc >/dev/null; then
  fancy_echo "Installing xcode ..."
  xcode-select --install
else
  fancy_echo "Xcode already installed. Skipping."
fi

# Install Homebrew
if ! command -v brew >/dev/null; then
  fancy_echo "Installing Homebrew..."
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" </dev/null
else
  fancy_echo "Homebrew already installed. Skipping."
fi

# [Install Ansible](http://docs.ansible.com/intro_installation.html).
if ! command -v ansible >/dev/null; then
  fancy_echo "Installing Ansible ..."
  brew install ansible
else
  fancy_echo "Ansible already installed. Skipping."
fi

# Clone the repository to your local drive.
if [ -d "${HOME}/.laptop" ]; then
  fancy_echo ".laptop repo dir exists. Skipping ..."
else
  fancy_echo "Cloning Laptop Repo ..."
  git clone $laptop_repo $HOME/.laptop
fi

fancy_echo "Changing to laptop repo dir ..."
cd $HOME/.laptop

export ANSIBLE_CONFIG=$HOME/.laptop/ansible.cfg

fancy_echo "Installing ansible roles ..."
ansible-galaxy install -r requirements.yml --force

# Run this from the same directory as this README file.
fancy_echo "Running ansible playbook for user ${install_user}..."
ansible-playbook playbook.yml -e install_user=$install_user -i hosts --ask-sudo-pass
