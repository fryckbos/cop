cd ..
source conf.sh
cd -
docker exec -it coscale_kafka kafka-consumer-groups --bootstrap-server ${NODES[1]}:9092 --list
