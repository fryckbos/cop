#!/bin/bash

source conf.sh
source services.sh

function show_help {
    echo "Usage: $0 [--version <version>] [<component>|all|data|coscale]"
}

if [ "$1" == "--help" ]; then
    show_help
    exit 0
fi

if [ "$1" == "--version" ]; then
    VERSION="$2"
    shift #move command line arguments to the left
    shift #move command line arguments to the left
fi

if [ $# -gt 1 ]; then
        show_help
        exit 1
fi

NAME=${1:-all}

docker login -u "$REGISTRY_USERNAME" -p "$REGISTRY_PASSWORD" $REGISTRY

if [ "$NAME" == "base" ]; then
    for SERVICE in base python java7 java8 rserve numpy; do
        IMG=coscale/$SERVICE:1.1.0
        docker pull $REGISTRY/$IMG
        docker tag $REGISTRY/$IMG $IMG
    done
    exit 0
fi

function pull {
    SERVICE=$1
    IMAGE_VERSION=$2
    IMG=coscale/$SERVICE:$IMAGE_VERSION
    docker pull $REGISTRY/$IMG
    docker tag $REGISTRY/$IMG $IMG
}

# Pull the third party services
for SERVICE in $DATA_SERVICES; do
    if [ "$NAME" == "all" ] || [ "$NAME" == "data" ] || [ "$NAME" == "$SERVICE" ]; then
        pull $SERVICE $VERSION
    fi
done

# Pull the coscale services
for SERVICE in $COSCALE_SERVICES $LB_SERVICE; do
    if [ "$NAME" == "all" ] || [ "$NAME" == "coscale" ] || [ "$NAME" == "$SERVICE" ]; then
        pull $SERVICE $VERSION
    fi
done

