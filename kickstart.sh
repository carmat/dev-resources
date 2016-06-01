#!/bin/bash

# Assumptions:
# ======================================
#
# * Xcode Command Line Tools installed (for gcc)

# Stop immediately if anything fails
set -e

############################################
# Handy functions
############################################

function cecho() {
  color=1 && bold=0  # white and not bold
  if [ $# -ge "2" ]; then
    if   [ $2 == 'red'    ]; then color=31
    elif [ $2 == 'green'  ]; then color=32
    elif [ $2 == 'yellow' ]; then color=33
    elif [ $2 == 'blue'   ]; then color=34
    elif [ $2 == 'purple' ]; then color=35
    elif [ $2 == 'teal'   ]; then color=36
    else
      color="1"  # white
    fi
  fi
  if [ "$3" == 'bold' ]; then
    bold=1
  fi
  echo -e "["`date +"%T"`"] \033["$bold";"$color"m"$1"\033[0;0m"
}

function ruby_installed() {
  local rubies=(`rbenv versions`)
  for x in ${rubies[@]}; do
    if [ "$x" == "$1" ]; then
      return 0
    fi
  done
  return 1
}

function install_ruby() {
  if ! (ruby_installed "$1"); then
    cecho "Installing ruby $1"
    rbenv install $1 && rbenv shell $1
    gem update --system
  fi
}

function file_contains() {
  if [ -s $1 ]; then
    lines=`grep "$2" "$1" | wc -l | tr -d ' '`
    if [ $lines -gt 0 ]; then
      return 0
    fi
  fi
  return 1
}

function add_if_not_contains() {
  if ! (file_contains "$1" "^$2"); then
    echo -e "$2" >> "$1"
  fi
}

function add_to_and_source() {
  add_if_not_contains "$1" "$2"
  source "$1"
}

function set_git_config() {
  read -e -p "$2 ($3): " INPUT && [[ ! "$INPUT" ]] && INPUT="$3"
  git config --global "$1" "$INPUT"
}

############################################
# Validate pre-requisites
############################################

# OS X version (10.X...): 9 = Mavericks; 10 = Yosemite; 11 = El Capitan
OSX_VERSION=`sw_vers -productVersion | cut -d. -f2`
if ! [[ " 9 10 11 " == *" $OSX_VERSION "* ]]; then
  cecho "Unknown OS X version: aborting." "red"
  exit 1
fi

############################################
# Ensure Xcode CLT installed for gcc
############################################

if ! [ -f "/Library/Developer/CommandLineTools/usr/bin/clang" ]; then
  cecho "Xcode Command Line Tools not installed" "red"
  if ( which xcode-select >/dev/null ); then
    read -p "Press return to install (expect a GUI popup)... "
    `xcode-select --install`
  else
    cecho "Please install via Xcode or from Apple's developer site" "blue"
    cecho "https://developer.apple.com/downloads/" "blue"
  fi
  cecho "Once installed, re-run this kickstart script" "blue"
  exit 1
fi

set +e; gcc --version >/dev/null 2>&1; status=$?; set -e
if [ "$status" -eq "69" ]; then
  cecho "Xcode license needs to be agreed to" "red"
  cecho "Run 'sudo xcodebuild -license' from your command line" "blue"
  cecho "Once you've agreed to the terms, re-run this kickstart script" "blue"
  exit 1
fi

############################################
# Homebrew (installs to /usr/local)
############################################

cecho "Installing Homebrew to /usr/local"
$( which brew >/dev/null ) || /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

############################################
# Standard applications
############################################

cecho "Installing standard applications"
add_to_and_source "$HOME/.bash_profile" \
  'export HOMEBREW_CASK_OPTS="--appdir=/Applications"'
brew tap caskroom/cask
brew cask install \
  virtualbox google-chrome firefox sequel-pro rowanj-gitx 1password spotify alfred
brew cask cleanup

############################################
# Git
############################################

cecho "Installing Git"
if [[ ! $(brew ls --versions git) ]]; then brew install git; fi

cecho "Setting up your Git config"
set_git_config "user.name" "Enter your full name" "Colm Morgan"
set_git_config "user.email" "Enter your email address" "colm.a.morgan@gmail.com"

cecho "Setting a few sensible Git defaults"
git config --global push.default upstream
git config --global branch.autosetuprebase always
git config --global merge.ff false

############################################
# Install rbenv + rubies + gems + bundler
############################################
# Use 'rbenv' and not 'RVM' because it relies on
# shims (not shell functions) so is easier to script.

cecho "Installing rbenv and ruby-build"
$( which rbenv >/dev/null) || brew install rbenv
$( which ruby-build > /dev/null ) || brew install ruby-build
add_to_and_source "$HOME/.bash_profile" 'eval "$(rbenv init -)"'
add_if_not_contains "$HOME/.gemrc" "install: --no-rdoc --no-ri"
add_if_not_contains "$HOME/.gemrc" "update: --no-rdoc --no-ri"

# El Capitan doesn't come with a linkable version of OpenSSL, so we need to
# install our own and ensure that all rubies + gems are built against it.
if [ "$OSX_VERSION" -eq 11 ]; then
  cecho "Ensuring Rubies build against Homebrew's OpenSSL"
  $( brew ls libyaml > /dev/null 2>&1 ) || brew install libyaml
  $( brew ls openssl > /dev/null 2>&1 ) || brew install openssl
  rbo_path=$(dirname ~/.rbenv/plugins/rbenv-homebrew-openssl/.)
  if [ ! -d $rbo_path ]; then
    git clone https://github.com/timblair/rbenv-homebrew-openssl.git $rbo_path
  fi
fi

cecho "Setting default gems to install for new Rubies"
$( brew ls rbenv-default-gems > /dev/null 2>&1 ) || brew install rbenv-default-gems
add_if_not_contains "$HOME/.rbenv/default-gems" "bundler"

cecho "Setting up per-project bundle and binstubs locations"
$( brew ls rbenv-binstubs > /dev/null 2>&1 ) || brew install rbenv-binstubs
mkdir -p "$HOME/.bundle"
add_if_not_contains "$HOME/.bundle/config" "---"
add_if_not_contains "$HOME/.bundle/config" "BUNDLE_PATH: .bundle"
add_if_not_contains "$HOME/.bundle/config" "BUNDLE_BIN: .bundle/bin"
add_if_not_contains "$HOME/.bundle/config" 'BUNDLE_DISABLE_SHARED_GEMS: "1"'
git config --global core.excludesfile ~/.gitignore
add_if_not_contains "$HOME/.gitignore" ".bundle"

# Default Ruby (latest stable)
$( which gsort >/dev/null ) || brew install coreutils # sorting version strings
RUBYV=$(ruby-build --definitions | grep -e "^\d.\d.\d\$" | gsort -V | tail -1)
install_ruby "$RUBYV"
rbenv global "$RUBYV"

############################################
#  App Dependencies
############################################

cecho "Installing app dependencies"
brew tap homebrew/dupes  # Required for LLVM gcc (apple-gcc42)
brew install apple-gcc42
