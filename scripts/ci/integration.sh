#!/bin/bash
set -ex

bundle install -j3
bundle clean --force

bundle exec rake spec:integration --trace
