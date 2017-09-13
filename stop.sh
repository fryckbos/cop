#!/bin/bash -e

source conf.sh
source services.sh

NAME=${1:-all}

if [ "$NAME" == "--help" ]; then
    echo "$0 : stop all services."
    echo "$0 <service> : stop a specific service."
    echo "$0 coscale : stop the CoScale services."
    exit 0
fi

# Before stopping all services, gather debug information
./diagnose.sh -tq inspect-service $NAME

function stop {
    SERVICE=$1

    echo "Stopping $SERVICE"
    docker stop coscale_$SERVICE || echo "(Container not running)"
    docker rm coscale_$SERVICE || echo "(Container not present)"
}

# Stop the data services
for SERVICE in $DATA_SERVICES; do
    if [ "$NAME" == "all" ] || [ "$NAME" == "data" ] || [ "$NAME" == "$SERVICE" ]; then
        stop $SERVICE
    fi
done

# Stop the coscale services
for SERVICE in $DEPENDENT_SERVICES $COSCALE_SERVICES $LB_SERVICE; do
    if [ "$NAME" == "all" ] || [ "$NAME" == "coscale" ] || [ "$NAME" == "$SERVICE" ]; then
        stop $SERVICE
    fi
done
