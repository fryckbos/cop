source ./conf.sh
docker exec -it coscale_kafka kafka-consumer-groups --bootstrap-server ${INTERNAL_NODES[1]}:9092 --describe --group $1

