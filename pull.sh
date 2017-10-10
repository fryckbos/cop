#!/bin/bash

source conf.sh
source services.sh

function show_help {
    echo "Usage: $0 [--version <version>] [--save] [<component>|all|data|coscale]"
    echo "    --version: overrides the version that is set in conf.sh"
    echo "    --save: creates coscale-<VERSION>.tar.gz that can be loaded on a different docker node"
    echo
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

SAVE=false
if [ "$1" == "--save" ]; then
    SAVE=true
    shift
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

function get_image {
    SERVICE=$1
    IMAGE_VERSION=$2
    echo coscale/$SERVICE:$IMAGE_VERSION
}

function pull {
    IMG=$1
    docker pull $REGISTRY/$IMG
    docker tag $REGISTRY/$IMG $IMG
}

IMAGES=""

# Pull the third party services
for SERVICE in $DATA_SERVICES; do
    if [ "$NAME" == "all" ] || [ "$NAME" == "data" ] || [ "$NAME" == "$SERVICE" ]; then
        IMG=$(get_image $SERVICE $VERSION)
        pull $IMG
        IMAGES="$IMAGES $IMG"
    fi
done

# Pull the coscale services
for SERVICE in $DEPENDENT_SERVICES $COSCALE_SERVICES $LB_SERVICE; do
    if [ "$NAME" == "all" ] || [ "$NAME" == "coscale" ] || [ "$NAME" == "$SERVICE" ]; then
        IMG=$(get_image $SERVICE $VERSION)
        pull $IMG
        IMAGES="$IMAGES $IMG"
    fi
done

# Pull the debug container
if [ "$NAME" == "all" ] || [ "$NAME" == "diag" ]; then
    IMG=$(get_image diag latest)
    pull $IMG
    IMAGES="$IMAGES $IMG"
fi

# Save the images to a tgz
if [ "$SAVE" == "true" ]; then
    echo ""
    echo "Using docker save to export the pulled images... This can take a few minutes..."
    docker save -o coscale-${VERSION}.tar $IMAGES
    echo "Gzipping the images... This can take a few minutes..."
    gzip coscale-${VERSION}.tar
    echo ""
    echo "The image archive is available in coscale-${VERSION}.tar.gz"
fi
