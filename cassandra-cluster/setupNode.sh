#!/bin/bash -e

if [ $# -lt 1 ]; then
    echo "Usage: `basename $0` seeds" 1>&2
    exit 255
fi

source ../conf.sh

docker run -d \
    -e CASSANDRA_IS_SEED=false \
    -e CASSANDRA_SEED_ADDRESS=$1 \
    -v `pwd`/../data/cassandra:/var/lib/cassandra:Z \
    --net=host \
    --restart unless-stopped \
    --name coscale_cassandra_node $REGISTRY/coscale/cassandra:$VERSION
