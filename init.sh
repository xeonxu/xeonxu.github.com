#!/bin/bash

brew install rbenv
brew install ruby-build
brew tap homebrew/dupes ; brew install apple-gcc42

rm -rf _deploy

git module update --init
git clone git@github.com:xeonxu/xeonxu.github.com.git _deploy -b master


