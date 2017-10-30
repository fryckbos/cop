#!/bin/bash

CASSANDRA='cassandra'
if [ "$USE_EXTERNAL_CASSANDRA" = true ] ; then
    CASSANDRA=''
fi

export DATA_SERVICES="rabbitmq $CASSANDRA memcached postgresql elasticsearch zookeeper"
export LB_SERVICE="haproxy"
export COSCALE_SERVICES="api app cron datastore streamingroller streamingrollerwriteback rum rumdatareceiver rumaggregator"
export DEPENDENT_SERVICES="kafka"
