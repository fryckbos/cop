#!/bin/bash -e

source conf.sh
source services.sh

export DNS_SWITCHES=""

NAME=${1:-all}

if [ "$NAME" == "--help" ]; then
    echo "$0 : run all services."
    echo "$0 <service> : run a specific service."
    echo "$0 coscale : run the CoScale services."
    exit 0
fi

function run {
    SERVICE=$1
    IMAGE_VERSION=$2

    if [ -e links/$SERVICE ]; then
        LINKS=`cat links/$SERVICE`
    else
        LINKS=""
    fi

    if [ -e expose/$SERVICE ]; then
        EXPOSED=`cat expose/$SERVICE`
    else
        EXPOSED=""
    fi

    VOLUMEFILE=volumes/$SERVICE
    VOLUMES=""
    if [ -e $VOLUMEFILE ]; then
      for ENTRY in $(<$VOLUMEFILE); do
        if [[ "$ENTRY" != "/"* ]]; then
            ENTRY=`pwd`/$ENTRY
        fi
        VOLUMES="${VOLUMES}-v ${ENTRY} "
      done
    fi

    echo "Starting $SERVICE:$IMAGE_VERSION"
    docker run -d \
        $LINKS $EXPOSED $VOLUMES $DNS_SWITCHES \
        -e "API_URL=$API_URL" \
        -e "API_SUPER_USER=$API_SUPER_USER" \
        -e "API_SUPER_PASSWD=$API_SUPER_PASSWD" \
        -e "APP_URL=$APP_URL" \
        -e "MAIL_SERVER=$MAIL_SERVER" \
        -e "MAIL_PORT=$MAIL_PORT" \
        -e "MAIL_SSL=$MAIL_SSL" \
        -e "MAIL_AUTH=$MAIL_AUTH" \
        -e "MAIL_USERNAME=$MAIL_USERNAME" \
        -e "MAIL_PASSWORD=$MAIL_PASSWORD" \
        -e "FROM_EMAIL=$FROM_EMAIL" \
        -e "SUPPORT_EMAIL=$SUPPORT_EMAIL" \
        -e "RUM_URL=$RUM_URL" \
        -e "ENABLE_HTTPS=$ENABLE_HTTPS" \
        -e "ANOMALY_EMAIL=$ANOMALY_EMAIL" \
        --name coscale_$SERVICE coscale/$SERVICE:$IMAGE_VERSION
}

# Run the data services
for SERVICE in $DATA_SERVICES; do
    if [ "$NAME" == "all" ] || [ "$NAME" == "$SERVICE" ]; then
        run $SERVICE $VERSION
    fi
done

if [ "$NAME" == "all" ]; then
    echo "Sleeping 30 seconds to bring the data services up."
    sleep 30
fi

# Run the coscale services
for SERVICE in $COSCALE_SERVICES $LB_SERVICE; do
    if [ "$NAME" == "all" ] || [ "$NAME" == "coscale" ] || [ "$NAME" == "$SERVICE" ]; then
        run $SERVICE $VERSION
    fi
done
