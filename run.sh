#!/bin/bash -e

source conf.sh
source services.sh

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

function get_service {
    echo $1 | grep -o -e '^[^0-9]*'
}

function get_seq {
    echo $1 | grep -o -e '[0-9]*$'
}

function run {
    SERVICE=$1
    IMAGE_VERSION=$2
    SEQ=$3

    ENV_VARS_CONF=`for VAR in $(cat conf.sh | grep '^export' | grep -v REGISTRY | awk '{ print $2; }' | awk -F= '{ print $1; }'); do echo '-e '${VAR}'='${!VAR}' '; done`

    echo "Starting $SERVICE:$IMAGE_VERSION $SEQ"

    # Don't bother when service is already running
    if [ "$(docker ps -a | grep coscale_$SERVICE$SEQ$)" ]; then
      echo "The service ${SERVICE}${SEQ} already exists."
    else
      docker run -d \
        $ENV_VARS_CONF $(./get-docker-opts.sh $SERVICE $SEQ) \
        -e "COSCALE_VERSION=$IMAGE_VERSION" \
        --restart on-failure \
        --hostname=coscale_$SERVICE$SEQ \
        --name coscale_$SERVICE$SEQ coscale/$SERVICE:$IMAGE_VERSION
    fi
}

# Run the data services
STARTED=0
for SERVICE in $DATA_SERVICES; do
    if [ "$NAME" == "all" ] || [ "$NAME" == "data" ] || [ "$NAME" == $(get_service "$SERVICE") ] || [ "$NAME" == "$SERVICE" ]; then
        run $(get_service $SERVICE) $VERSION $(get_seq $SERVICE)
        STARTED=1
    fi
done

if [ "$STARTED" == "1" ]; then
    echo "Sleeping 30 seconds to bring the data services up."
    sleep 30
fi

# Run the coscale services
for SERVICE in $COSCALE_SERVICES $LB_SERVICE; do
    if [ "$NAME" == "all" ] || [ "$NAME" == "coscale" ] || [ "$NAME" == $(get_service "$SERVICE") ] || [ "$NAME" == "$SERVICE" ]; then
        run $(get_service $SERVICE) $VERSION $(get_seq $SERVICE)
        STARTED=1
    fi
done

# Raise an error if no containers were started
if [ "$STARTED" == "0" ]; then
    echo "Error: no containers started."
    exit 1
fi
