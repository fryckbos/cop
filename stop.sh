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

# Services which handle the SIGTERM well and shutdown themselves asap -> They get a higher timeout
# in case they have some work to do for a proper shutdown.
COOPERATIVE_SERVICES="kafka zookeeper"

function get_service {
    echo $1 | grep -o -e '^[^0-9]*'
}

function get_seq {
    echo $1 | grep -o -e '[0-9]*$'
}

#Define reverse lists to support stopping in reverse order
function reverse {
    local out=()
    while [ $# -gt 0 ]; do
        out=("$1" "${out[@]}")
        shift 1
    done
    echo "${out[@]}"
}

DATA_SERVICES_REV=$(reverse $DATA_SERVICES)
COSCALE_SERVICES_REV=$(reverse $COSCALE_SERVICES)
DEPRECATED_SERVICES_REV=$(reverse $DEPRECATED_SERVICES)

function stop {
    SERVICE=$1
    TIMEOUT=""

    if [[ "$COOPERATIVE_SERVICES" == *"$(get_service ${SERVICE})"* ]]; then
        echo "Stopping $SERVICE with timeout of 60s";
        TIMEOUT="--time 180"
    else
        echo "Stopping $SERVICE with default timeout";
    fi

    echo docker stop $TIMEOUT coscale_$SERVICE || echo "(Container not running)"
    echo docker rm coscale_$SERVICE || echo "(Container not present)"
}

# Stop the deprecated services
for SERVICE in $DEPRECATED_SERVICES_REV; do
    if [ "$NAME" == "all" ] || [ "$NAME" == "coscale" ] || [ "$NAME" == "data" ]; then
        # Don't bother when service is not running
        if [ "$(docker ps -a | grep coscale_$SERVICE$)" ]; then
            echo "Service $SERVICE is deprecated, stopping it..."
            stop $SERVICE
        fi
    fi
done

# Stop the coscale services
for SERVICE in $LB_SERVICE $COSCALE_SERVICES_REV; do
    if [ "$NAME" == "all" ] || [ "$NAME" == "coscale" ] || [ "$NAME" == $(get_service "$SERVICE") ] || [ "$NAME" == "$SERVICE" ]; then
        stop $SERVICE
    fi
done


# Stop the data services
for SERVICE in $DATA_SERVICES_REV; do
    if [ "$NAME" == "all" ] || [ "$NAME" == "data" ] || [ "$NAME" == "$SERVICE" ]; then
        stop $SERVICE
    fi
done

