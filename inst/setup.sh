#!/bin/sh

PRODUCTION=""

if [ "$1" = "-p" ]; then
  PRODUCTION="RAILS_ENV=production"
fi

bundle install --path vendor/bundle/

if [ "$2" = "-d" ]; then
  bundle exec rake db:drop $PRODUCTION
fi
bundle exec rake db:create $PRODUCTION
bundle exec rake db:migrate $PRODUCTION

if [ "$1" = "-p" ]; then
  bundle exec rake assets:clobber $PRODUCTION
  bundle exec rake assets:precompile $PRODUCTION
fi
