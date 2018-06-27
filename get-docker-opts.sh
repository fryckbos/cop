#!/bin/bash -e

DEFAULT=0
if [ "$1" = "--default" ]; then
    shift
    DEFAULT=1
fi

source services.sh

function echo_service_if_exists {
    echo "$DATA_SERVICES $LB_SERVICE $COSCALE_SERVICES" | grep -o $1
}

if [ $DEFAULT == 0 ] && [ -f get-docker-opts.override ]; then
    exec ./get-docker-opts.override $*
else
    SERVICE=$1

    LINKFILE=links/$SERVICE
    LINKS=""
    if [ -f $LINKFILE ]; then
        for ENTRY in $(<$LINKFILE); do
            if [[ "$(echo_service_if_exists $ENTRY)" != "" ]]; then
                LINKS="${LINKS}--link coscale_${ENTRY}:${ENTRY} "
            fi
        done
    fi

    EXPOSED=""
    if [ -f expose/$SERVICE ]; then
        EXPOSED=$(cat expose/$SERVICE)
    fi

    VOLUMEFILE=volumes/$SERVICE
    VOLUMES=""
    if [ -f $VOLUMEFILE ]; then
      for ENTRY in $(<$VOLUMEFILE); do
        if [[ "$ENTRY" != "/"* ]]; then
            ENTRY=$(pwd)/$ENTRY
        fi
        VOLUMES="${VOLUMES}-v ${ENTRY}:z "
      done
    fi

    LOG_ROTATE="--log-opt max-size=100m --log-opt max-file=10 "

    if [ -f misc/$SERVICE ]; then
        MISC=$(cat misc/$SERVICE)
    else
        MISC=""
    fi

    echo "$LINKS $EXPOSED $VOLUMES $LOG_ROTATE $MISC"
fi
