#!/bin/bash

CASSANDRA='cassandra'
if [ "$USE_EXTERNAL_CASSANDRA" = true ] ; then
    CASSANDRA=''
fi

export DATA_SERVICES="rabbitmq $CASSANDRA memcached postgresql elasticsearch"
export LB_SERVICE="haproxy"
export COSCALE_SERVICES="alerter api app cron datastore mailer pageminer reporter anomalymatcher triggermatcher rum rumdatareceiver collector rumaggregator"
export DEPRECATED_SERVICES=""

if [ "$COSCALE_STREAMING_ENABLED" = true ] ; then
    DATA_SERVICES="$DATA_SERVICES zookeeper kafka"
    COSCALE_SERVICES="$COSCALE_SERVICES streamingtriggermatcher streamingroller streamingrollerwriteback anomalydetector anomalyaggregator"
    DEPRECATED_SERVICES="$DEPRECATED_SERVICES roller analysismanager anomalydetectorservice"
else
    COSCALE_SERVICES="$COSCALE_SERVICES roller analysismanager anomalydetectorservice"
    DEPRECATED_SERVICES="$DEPRECATED_SERVICES kafka zookeeper streamingtriggermatcher streamingroller streamingrollerwriteback anomalydetector anomalyaggregator"
fi
