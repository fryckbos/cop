#!/bin/bash

CASSANDRA='cassandra'
if [ "$USE_EXTERNAL_CASSANDRA" = true ] ; then
    CASSANDRA=''
fi

export DATA_SERVICES="rabbitmq $CASSANDRA memcached postgresql elasticsearch zookeeper"
export LB_SERVICE="haproxy"
export COSCALE_SERVICES="alerter api app cron datastore mailer pageminer reporter anomalymatcher triggermatcher streamingtriggermatcher rum rumdatareceiver collector rumaggregator streamingroller streamingrollerwriteback anomalydetector anomalydetectorfeeder anomalyaggregator"
export DEPENDENT_SERVICES="kafka"
