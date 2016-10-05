#!/bin/bash

source conf.sh
source services.sh

docker login -u "$REGISTRY_USERNAME" -p "$REGISTRY_PASSWORD" -e "$REGISTRY_EMAIL" $REGISTRY

for SERVICE in $DATA_SERVICES; do
    IMG=coscale/$SERVICE:1.0.0
    docker pull $REGISTRY/$IMG
    docker tag $REGISTRY/$IMG $IMG
done

for SERVICE in $COSCALE_SERVICES $LB_SERVICE; do
    IMG=coscale/$SERVICE:$VERSION
    docker pull $REGISTRY/$IMG
    docker tag $REGISTRY/$IMG $IMG
done

