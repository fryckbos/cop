#!/bin/bash

source conf.sh

export TEST_HEALTH_ALERT=true
export CHECK_PERIOD=60

ERROR=0

if [ x"$MAIL_SERVER" == "x" ]; then
    echo "Please set MAIL_SERVER in conf.sh before installing."
    ERROR=1
fi
if [ x"$MAIL_PORT" == "x" ]; then
    echo "Please set MAIL_PORT in conf.sh before installing."
    ERROR=1
fi
if [ x"$MAIL_SSL" == "x" ]; then
    echo "Please set MAIL_SSL in conf.sh before installing."
    ERROR=1
fi
if [ x"$MAIL_AUTH" == "x" ]; then
    echo "Please set MAIL_AUTH in conf.sh before installing."
    ERROR=1
fi
if [ x"$FROM_EMAIL" == "x" ]; then
    echo "Please set FROM_EMAIL in conf.sh before installing."
    ERROR=1
fi
if [ x"$SUPPORT_EMAIL" == "x" ]; then
    echo "Please set SUPPORT_EMAIL in conf.sh before installing."
    ERROR=1
fi
if [ x"$API_SUPER_USER" == "x" ]; then
    echo "Please set API_SUPER_USER in conf.sh before installing."
    ERROR=1
fi
if [ x"$API_SUPER_PASSWD" == "x" ]; then
    echo "Please set API_SUPER_PASSWD in conf.sh before installing."
    ERROR=1
fi
if [ x"$API_URL" == "x" ]; then
    echo "Please set API_URL in conf.sh before installing."
    ERROR=1
fi
if [ x"$APP_URL" == "x" ]; then
    echo "Please set APP_URL in conf.sh before installing."
    ERROR=1
fi
if [ x"$RUM_URL" == "x" ]; then
    echo "Please set RUM_URL in conf.sh before installing."
    ERROR=1
fi

if [ "$ERROR" != "0" ]; then
    exit 1
fi

docker run -d \
    -e "MAIL_SERVER=$MAIL_SERVER" \
    -e "MAIL_PORT=$MAIL_PORT" \
    -e "MAIL_SSL=$MAIL_SSL" \
    -e "MAIL_AUTH=$MAIL_AUTH" \
    -e "MAIL_USERNAME=$MAIL_USERNAME" \
    -e "MAIL_PASSWORD=$MAIL_PASSWORD" \
    -e "FROM_EMAIL=$FROM_EMAIL" \
    -e "SUPPORT_EMAIL=$SUPPORT_EMAIL" \
    -e "API_SUPER_USER=$API_SUPER_USER" \
    -e "API_SUPER_PASSWD=$API_SUPER_PASSWD" \
    -e "API_URL=$API_URL" \
    -e "APP_URL=$APP_URL" \
    -e "RUM_URL=$RUM_URL" \
    -e "TEST_HEALTH_ALERT=$TEST_HEALTH_ALERT" \
    -e "CHECK_PERIOD=$CHECK_PERIOD" \
    --restart always \
    --name coscale_healthchecker coscale/healthchecker:1.0.0
