#!/bin/bash -e

if [ $# -lt 1 ]; then
    echo "Usage: `basename $0` replication_factor" 1>&2
    exit 255
fi

source ../conf.sh

docker run -d \
    -e CASSANDRA_IS_SEED=true \
    -e CASSANDRA_REPLICATION_FACTOR=$1 \
    -v `pwd`/../data/cassandra:/var/lib/cassandra:Z \
    --net=host \
    --restart unless-stopped \
    --name coscale_cassandra_seed $REGISTRY/coscale/cassandra:$VERSION
