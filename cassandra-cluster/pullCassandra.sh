#!/bin/bash -e

source ../conf.sh

docker login -u "$REGISTRY_USERNAME" -p "$REGISTRY_PASSWORD" $REGISTRY

function pull {
    SERVICE=$1
    IMAGE_VERSION=$2
    IMG=coscale/$SERVICE:$IMAGE_VERSION
    docker pull $REGISTRY/$IMG
    docker tag $REGISTRY/$IMG $IMG
}

pull cassandra $VERSION
