#!/bin/bash -e

DEFAULT=0
if [ "$1" = "--default" ]; then
    shift
    DEFAULT=1
fi

if [ $DEFAULT == 0 ] && [ -f get-docker-opts.override ]; then
    exec ./get-docker-opts.override $*
else
    SERVICE=$1

    if [ -f links/$SERVICE ]; then
        LINKS=$(cat links/$SERVICE)
        if [ "$SERVICE" = 'datastore' ] && [ "$USE_EXTERNAL_CASSANDRA" = true ]; then
            LINKS=$(echo $LINKS | sed 's/--link coscale_cassandra:cassandra//g')
        fi
        if [ "$COSCALE_STREAMING_ENABLED" != true ]; then
            LINKS=$(echo $LINKS | sed 's/--link coscale_kafka:kafka//g')
        fi
    else
        LINKS=""
    fi

    if [ -f expose/$SERVICE ]; then
        EXPOSED=$(cat expose/$SERVICE)
    else
        EXPOSED=""
    fi

    VOLUMEFILE=volumes/$SERVICE
    VOLUMES=""
    if [ -f $VOLUMEFILE ]; then
      for ENTRY in $(<$VOLUMEFILE); do
        if [[ "$ENTRY" != "/"* ]]; then
            ENTRY=$(pwd)/$ENTRY
        fi
        VOLUMES="${VOLUMES}-v ${ENTRY}:Z "
      done
    fi

    if [ -f misc/$SERVICE ]; then
        MISC=$(cat misc/$SERVICE)
    else
        MISC=""
    fi

    echo "$LINKS $EXPOSED $VOLUMES $MISC"
fi
