. conf.sh
docker run -it --rm --link coscale_kafka:kafka coscale/streamingroller:$VERSION java -cp /opt/coscale/streamingroller/bin/streamingroller-$VERSION-jar-with-dependencies.jar coscale.streamingcore.kafka.CreateAllTopics -h kafka:9092 $@
