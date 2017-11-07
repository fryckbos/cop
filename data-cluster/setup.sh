#!/bin/bash -e

if [ $# -lt 1 ]; then
    echo "Usage: `basename $0` node-id {service}" 1>&2
    echo "       node-id: index of this node in the NODES array in conf.sh (starts from 1)"
    echo "       service: the service to setup (cassandra, zookeeper, kafka). Default: all"
    exit 255
fi

source conf.sh

INDEX=$1
SERVICE=${2:all}
echo "Setting up ${SERVICE} node $INDEX : ${NODES[$((INDEX-1))]}"

function join_strings {
    POSTFIX=$1
    shift
    SEPARATOR=$1
    shift

    OUTPUT=""
    while [[ "$1" != "" ]]; do
        PART="${1}${POSTFIX}"
        if [[ "$OUTPUT" == "" ]]; then
            OUTPUT="${PART}"
        else
            OUTPUT="${OUTPUT}${SEPARATOR}${PART}"
        fi
        shift
    done

    echo $OUTPUT
}

if [[ "$SERVICE" == "all" ]] || [[ "$SERVICE" == "cassandra" ]]; then
    # Setup Cassandra
    if [[ "$INDEX" == "1" ]]; then
        docker run -d \
            -e CASSANDRA_IS_SEED=true \
            -e CASSANDRA_REPLICATION_FACTOR=${REPLICATION_FACTOR} \
            -v `pwd`/../data/cassandra:/var/lib/cassandra:Z \
            --net=host \
            --restart unless-stopped \
            --name coscale_cassandra_seed $REGISTRY/coscale/cassandra:$VERSION
    else
        docker run -d \
            -e CASSANDRA_IS_SEED=false \
            -e CASSANDRA_SEED_ADDRESS=${NODES[0]} \
            -v `pwd`/../data/cassandra:/var/lib/cassandra:Z \
            --net=host \
            --restart unless-stopped \
            --name coscale_cassandra_node $REGISTRY/coscale/cassandra:$VERSION
    fi
fi

if [[ "$SERVICE" == "all" ]] || [[ "$SERVICE" == "zookeeper" ]]; then
    # Setup Zookeeper
    docker run -d \
        -e ZOOKEEPER_SERVER_ID=$INDEX \
        -e ZOOKEEPER_CLIENT_PORT=32181 \
        -e ZOOKEEPER_SERVERS="$(join_strings ":32888:33888" ";" ${NODES[@]})" \
        -e ZOOKEEPER_TICK_TIME=2000 \
        -e ZOOKEEPER_INIT_LIMIT=5 \
        -e ZOOKEEPER_SYNC_LIMIT=2 \
        -e KAFKA_JMX_PORT=9997 \
        -e KAFKA_JMX_HOSTNAME=localhost \
        -v `pwd`/../data/zookeeper/data:/var/lib/zookeeper/data:Z \
        -v `pwd`/../data/zookeeper/log:/var/lib/zookeeper/log:Z \
        -v `pwd`/../data/zookeeper/secrets:/etc/zookeeper/secrets:Z \
        --net=host \
        --restart unless-stopped \
        --name coscale_zookeeper $REGISTRY/coscale/zookeeper:$VERSION
fi

if [[ "$SERVICE" == "all" ]] || [[ "$SERVICE" == "kafka" ]]; then
    # Setup Kafka
    docker run -d \
        -e KAFKA_BROKER_ID=$INDEX \
        -e KAFKA_ZOOKEEPER_CONNECT="$(join_strings ":32181" "," ${NODES[@]})" \
        -e KAFKA_ADVERTISED_LISTENERS="PLAINTEXT://${NODES[$((INDEX-1))]}:9092" \
        -e KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=${REPLICATION_FACTOR} \
        -e KAFKA_JMX_PORT=9998 \
        -e KAFKA_JMX_HOSTNAME=localhost \
        -e KAFKA_AUTO_CREATE_TOPICS_ENABLE=false \
        -e KAFKA_LOG4J_ROOT_LOGLEVEL=INFO \
        -e GROUP_INITIAL_REBALANCE_DELAY_MS=60000 \
        -v `pwd`/../data/kafka/data:/var/lib/kafka/data:Z \
        -v `pwd`/../data/kafka/secrets:/etc/kafka/secrets:Z \
        --net=host \
        --restart unless-stopped \
        --name coscale_kafka $REGISTRY/coscale/kafka:$VERSION
fi
