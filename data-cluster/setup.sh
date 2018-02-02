#!/bin/bash -e

if [ $# -lt 1 ]; then
    echo "Usage: `basename $0` node-id {service}" 1>&2
    echo "       node-id: index of this node in the NODES array in conf.sh (starts from 1)"
    echo "       service: the service to setup (all, cassandra, streaming, zookeeper, kafka, streamingroller, anomalydetector, streamingtriggermatcher, anomalydetectorfeeder, anomalyaggregator). Default: all"
    exit 255
fi

source conf.sh

INDEX=$1
SERVICE=${2:all}

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
        echo "Setting up cassandra seed node : ${NODES[$((INDEX-1))]}"

        docker run -d \
            -e CASSANDRA_IS_SEED=true \
            -e CASSANDRA_REPLICATION_FACTOR=${REPLICATION_FACTOR} \
            -v `pwd`/../data/cassandra:/var/lib/cassandra:Z \
            --net=host \
            --restart unless-stopped \
            --name coscale_cassandra_seed $REGISTRY/coscale/cassandra:$VERSION
    else
        echo "Setting up cassandra node $INDEX : ${NODES[$((INDEX-1))]}"

        docker run -d \
            -e CASSANDRA_IS_SEED=false \
            -e CASSANDRA_SEED_ADDRESS=${NODES[0]} \
            -v `pwd`/../data/cassandra:/var/lib/cassandra:Z \
            --net=host \
            --restart unless-stopped \
            --name coscale_cassandra_node $REGISTRY/coscale/cassandra:$VERSION
    fi
fi

if [[ "$SERVICE" == "all" ]] || [[ "$SERVICE" == "streaming" ]] || [[ "$SERVICE" == "zookeeper" ]]; then
    # Setup Zookeeper
    echo "Setting up zookeeper node $INDEX : ${INTERNAL_NODES[$((INDEX-1))]}"

    docker run -d \
        -e ZOOKEEPER_SERVER_ID=$INDEX \
        -e ZOOKEEPER_CLIENT_PORT=2181 \
        -e ZOOKEEPER_SERVERS="$(join_strings ":2888:3888" ";" ${INTERNAL_NODES[@]})" \
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

if [[ "$SERVICE" == "all" ]] || [[ "$SERVICE" == "streaming" ]] || [[ "$SERVICE" == "kafka" ]]; then
    # Setup Kafka
    echo "Setting up kafka node $INDEX : ${NODES[$((INDEX-1))]}"

    docker run -d \
        -e KAFKA_BROKER_ID=$INDEX \
        -e KAFKA_ZOOKEEPER_CONNECT="$(join_strings ":2181" "," ${INTERNAL_NODES[@]})" \
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

if [[ "$SERVICE" == "all" ]] || [[ "$SERVICE" == "streaming" ]] || [[ "$SERVICE" == "streamingroller" ]]; then
    # Setup Streamingroller
    echo "Setting up streamingroller node $INDEX : ${NODES[$((INDEX-1))]}"

    docker run -d \
        -e COSCALE_STREAMING_GROUPROLLER_ENABLED=true \
        --net=host \
        --restart unless-stopped \
        --add-host "kafka:${INTERNAL_NODES[$((INDEX-1))]}" \
        --name coscale_streamingroller $REGISTRY/coscale/streamingroller:$VERSION
fi

if [[ "$SERVICE" == "all" ]] || [[ "$SERVICE" == "streaming" ]] || [[ "$SERVICE" == "anomalydetector" ]]; then
    # Setup Anomalydetector
    echo "Setting up anomalydetector node $INDEX : ${NODES[$((INDEX-1))]}"

    docker run -d \
        --net=host \
        --restart unless-stopped \
        --add-host "kafka:${INTERNAL_NODES[$((INDEX-1))]}" \
    	-e JMX_PORT=6667 \
        --name coscale_anomalydetector $REGISTRY/coscale/anomalydetector:$VERSION
fi

if [[ "$SERVICE" == "all" ]] || [[ "$SERVICE" == "streaming" ]] || [[ "$SERVICE" == "streamingtriggermatcher" ]]; then
    # Setup Streamgintriggermatcher
    echo "Setting up streamingtriggermatcher node $INDEX : ${NODES[$((INDEX-1))]}"

    docker run -d \
        --restart unless-stopped \
        --add-host "kafka:${INTERNAL_NODES[$((INDEX-1))]}" \
    	--add-host "rabbitmq:${INTERNAL_NODES[$((INDEX-1))]}" \
    	--add-host "api-staad.coscale.com:${INTERNAL_NODES[$((INDEX-1))]}" \
        -e "API_URL=$API_URL" \
        -e "API_SUPER_USER=$API_SUPER_USER" \
        -e "API_SUPER_PASSWD=$API_SUPER_PASSWD" \
        --name coscale_streamingtriggermatcher $REGISTRY/coscale/streamingtriggermatcher:$VERSION
fi

if [[ "$SERVICE" == "all" ]] || [[ "$SERVICE" == "streaming" ]] || [[ "$SERVICE" == "anomalyaggregator" ]]; then
    # Setup Anomalyaggregator
    echo "Setting up anomalyaggregator node $INDEX : ${NODES[$((INDEX-1))]}"

    docker run -d \
        --restart unless-stopped \
        --add-host "kafka:${INTERNAL_NODES[$((INDEX-1))]}" \
        --add-host "api-staad.coscale.com:${INTERNAL_NODES[$((INDEX-1))]}" \
        -e "API_URL=$API_URL" \
        -e "API_SUPER_USER=$API_SUPER_USER" \
        -e "API_SUPER_PASSWD=$API_SUPER_PASSWD" \
        --name coscale_anomalyaggregator $REGISTRY/coscale/anomalyaggregator:$VERSION
fi
