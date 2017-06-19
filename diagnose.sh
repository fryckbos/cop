#!/bin/bash

source conf.sh
source services.sh

ACTION=${1:-help}

if [ "$ACTION" == "help" ]; then

    echo "$0 check-containers: check whether all containers are running."
    exit 0

elif [ "$ACTION" == "check-containers" ]; then

    UP=1
    CONTAINERS_DOWN=""

    for SERVICE in $DATA_SERVICES $COSCALE_SERVICES $LB_SERVICE; do
        OUTPUT=`docker inspect -f {{.State.Running}} coscale_$SERVICE`
        if [ "$?" == "1" -o "$OUTPUT" == "false" ]; then
            UP=0
            CONTAINERS_DOWN="$SERVICE $CONTAINERS_DOWN"
        fi
    done

    if [ "$UP" == "1" ]; then
        echo "All containers are running."
        exit 0
    else
        echo "The following containers are down: $CONTAINERS_DOWN"
        exit 1
    fi

fi

