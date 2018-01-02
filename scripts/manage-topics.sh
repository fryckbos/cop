. conf.sh
docker run -it --rm coscale/streamingroller:$VERSION java -cp /opt/coscale/streamingroller/bin/streamingroller-$VERSION-jar-with-dependencies.jar coscale.streamingcore.kafka.ManageTopics -h kafka1:9092 $@
