source ./conf.sh
docker exec -it coscale_kafka kafka-topics --zookeeper ${INTERNAL_NODES[1]}:2181 --list
