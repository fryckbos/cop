#!/bin/bash

source conf.sh

SLACK=1
KEEP=30

if [ "$1" == "list" ]; then
  ./connect.sh cron java -cp /opt/coscale/cron/bin/cron-${VERSION}-jar-with-dependencies.jar coscale.cron.CassandraCleanerWorker -r rabbitmq --slack ${SLACK} --keep ${KEEP} list
elif [ "$1" == "delete" ]; then
  ./connect.sh cron java -cp /opt/coscale/cron/bin/cron-${VERSION}-jar-with-dependencies.jar coscale.cron.CassandraCleanerWorker -r rabbitmq --slack ${SLACK} --keep ${KEEP} delete
else
  echo "usage: $0 <list|delete>"
fi
