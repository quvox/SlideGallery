#!/bin/sh
#
# This script should be run in the case that you use Apache as a web server.
#

APACHEUSER=www-data

APACHEHOME=`su - -s /bin/csh $APACHEUSER -c "printenv HOME"`
chown $APACHEUSER $APACHEHOME
