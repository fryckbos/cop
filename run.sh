#!/bin/bash -e

source conf.sh
source services.sh

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
    IMAGE_VERSION=$2

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

    if [ -e misc/$SERVICE ]; then
        MISC=`cat misc/$SERVICE`
    else
        MISC=""
    fi

    ENV_VARS_CONF=`for VAR in $(cat conf.sh | grep '^export' | grep -v REGISTRY | awk '{ print $2; }' | awk -F= '{ print $1; }'); do echo '-e "'${VAR}'='${!VAR}'" \'; done`

    echo "Starting $SERVICE:$IMAGE_VERSION"
    docker run -d \
        $LINKS $EXPOSED $VOLUMES $DNS_SWITCHES $MISC $ENV_VARS_CONF \
        -e "COSCALE_VERSION=$IMAGE_VERSION" \
        -e "KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://$KAFKA_URL:9092" \
        --name coscale_$SERVICE coscale/$SERVICE:$IMAGE_VERSION
}

# Run the data services
for SERVICE in $DATA_SERVICES; do
    if [ "$NAME" == "all" ] || [ "$NAME" == "data" ] || [ "$NAME" == "$SERVICE" ]; then
        run $SERVICE $VERSION
    fi
done


if [ "$NAME" == "all" ]; then
    echo "Sleeping 30 seconds to bring the data services up."
    sleep 30
fi

# Run the coscale services
for SERVICE in $DEPENDENT_SERVICES $COSCALE_SERVICES $LB_SERVICE; do
    if [ "$NAME" == "all" ] || [ "$NAME" == "coscale" ] || [ "$NAME" == "$SERVICE" ]; then
        run $SERVICE $VERSION
    fi
done

