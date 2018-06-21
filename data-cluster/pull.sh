#!/bin/bash -e

source conf.sh

docker login -u "$REGISTRY_USERNAME" -p "$REGISTRY_PASSWORD" $REGISTRY

SERVICE=${1:-all}

function pull {
    IMAGE_NAME=$1
    IMAGE_VERSION=$2
    IMG=coscale/$IMAGE_NAME:$IMAGE_VERSION
    docker pull $REGISTRY/$IMG
    docker tag $REGISTRY/$IMG $IMG
}

if [[ "$SERVICE" == "all" ]] || [[ "$SERVICE" == "cassandra" ]]; then
    pull cassandra $VERSION
fi

if [[ "$SERVICE" == "all" ]] || [[ "$SERVICE" == "elasticsearch" ]]; then
    pull elasticsearch $VERSION
fi

if [[ "$SERVICE" == "all" ]] || [[ "$SERVICE" == "streaming" ]] || [[ "$SERVICE" == "zookeeper" ]]; then
    pull zookeeper $VERSION
fi

if [[ "$SERVICE" == "all" ]] || [[ "$SERVICE" == "streaming" ]] || [[ "$SERVICE" == "kafka" ]]; then
    pull kafka $VERSION
fi

if [[ "$SERVICE" == "all" ]] || [[ "$SERVICE" == "streaming" ]] || [[ "$SERVICE" == "streamingroller" ]]; then
    pull streamingroller $VERSION
fi

if [[ "$SERVICE" == "all" ]] || [[ "$SERVICE" == "streaming" ]] || [[ "$SERVICE" == "anomalydetector" ]]; then
    pull anomalydetector $VERSION
fi

if [[ "$SERVICE" == "all" ]] || [[ "$SERVICE" == "streaming" ]] || [[ "$SERVICE" == "streamingtriggermatcher" ]]; then
    pull streamingtriggermatcher $VERSION
fi

if [[ "$SERVICE" == "all" ]] || [[ "$SERVICE" == "streaming" ]] || [[ "$SERVICE" == "anomalyaggregator" ]]; then
    pull anomalyaggregator $VERSION
fi
