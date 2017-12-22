#!/bin/bash -e
cd ..
source conf.sh
cd -

docker run -it --rm  coscale/streamingroller:$VERSION java -cp /opt/coscale/streamingroller/bin/streamingroller-$VERSION-jar-with-dependencies.jar coscale.streamingcore.kafka.ManageTopics -h ${NODES[1]}:9092 $@
