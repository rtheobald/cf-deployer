#!/bin/bash
set -ex

bundle install -j3
bundle clean --force

bundle exec rake quality:rubocop spec:unit --trace
