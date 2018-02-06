#!/bin/bash -e

SEQ=$2

source conf.sh
source services.sh
source custom-settings.sh


export DNS_SWITCHES=""

if [ "$1" == "--version" ]; then
    VERSION="$2"
    shift #move command line arguments to the left
    shift #move command line arguments to the left
fi

NAME=${1:-all}

if [ "$NAME" == "--help" ]; then
    echo "$0 [--version <version>]: run all services."
    echo "$0 [--version <version>] <service> : run a specific service."
    echo "$0 [--version <version>] coscale : run the CoScale services."
    exit 0
fi

function run {
    SERVICE=$1
    SEQ=$2
    IMAGE_VERSION=$3

    HOSTNAME=${SERVICE}${SEQ}
    IP=$(cat custom-ips.txt | grep "^${HOSTNAME}=" | cut -d'=' -f2)
    echo "Starting [${HOSTNAME}] with IP [${IP}]"

    if [ -e links/$SERVICE ]; then
        LINKS=`cat links/$SERVICE`
        if [ "$SERVICE" = 'datastore' ] && [ "$USE_EXTERNAL_CASSANDRA" = true ]; then
            LINKS=$(echo $LINKS | sed 's/--link coscale_cassandra:cassandra//g')
        fi
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
        VOLUMES="${VOLUMES}-v ${ENTRY}:Z "
      done
    fi

    HOSTNAME=${SERVICE}${SEQ}

    #CUSTOM ACTIONS FOR SERVICE
    if [ -f custom-${SERVICE}.conf ]; then
      echo "Custom config for service [${SERVICE}]"
      source custom-${SERVICE}.conf
    fi

    #CUSTOM ACTIONS FOR CONTAINER
    if [ -f custom-${HOSTNAME}.conf ]; then
      echo "Custom config for hostname [${HOSTNAME}]"
      source custom-${HOSTNAME}.conf
    fi

    echo "Starting $SERVICE:$IMAGE_VERSION"
    docker run -d \
        --name coscale_${HOSTNAME} \
        --net cs-int \
        --ip ${IP} \
        --dns=${DNS1} \
        --dns-search=${ENVID}.coscale.com \
        --hostname=${HOSTNAME} \
        $LINKS $EXPOSED $VOLUMES $DNS_SWITCHES $EXTRA_RUN_PARAMS \
        -e "API_URL=$API_URL" \
        -e "API_SUPER_USER=$API_SUPER_USER" \
        -e "API_SUPER_PASSWD=$API_SUPER_PASSWD" \
        -e "APP_URL=$APP_URL" \
        -e "MAIL_SERVER=$MAIL_SERVER" \
        -e "MAIL_PORT=$MAIL_PORT" \
        -e "MAIL_SSL=$MAIL_SSL" \
        -e "MAIL_TLS=$MAIL_TLS" \
        -e "MAIL_AUTH=$MAIL_AUTH" \
        -e "MAIL_USERNAME=$MAIL_USERNAME" \
        -e "MAIL_PASSWORD=$MAIL_PASSWORD" \
        -e "FROM_EMAIL=$FROM_EMAIL" \
        -e "SUPPORT_EMAIL=$SUPPORT_EMAIL" \
        -e "RUM_URL=$RUM_URL" \
        -e "ENABLE_HTTPS=$ENABLE_HTTPS" \
        -e "ANOMALY_EMAIL=$ANOMALY_EMAIL" \
        -e "COSCALE_VERSION=$IMAGE_VERSION" \
        -e "CASSANDRA_CLEANER_SLACK=$CASSANDRA_CLEANER_SLACK" \
        -e "USE_EXTERNAL_CASSANDRA=$USE_EXTERNAL_CASSANDRA" \
        -e "EXTERNAL_CASSANDRA_ENDPOINTS=$EXTERNAL_CASSANDRA_ENDPOINTS" \
        -e "DATASTORE_THREADS=$DATASTORE_THREADS" \
        -e "MEMORY_PROFILE=$MEMORY_PROFILE" \
        coscale/$SERVICE:$IMAGE_VERSION

  ./custom-updatens.sh ${HOSTNAME}.${ENVID}.coscale.com ${IP}


}



SERVICE=${NAME}

run $SERVICE $SEQ $VERSION


