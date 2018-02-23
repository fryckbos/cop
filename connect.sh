#!/bin/bash -e
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <service> [action]"
  echo "   action"
  echo "     bash : starts an interactive bash console (default)"
  echo "     log : get the full service log"
  echo "     tail : get a tailf of the service log"
  echo "     jstack : create a jstack of the Java process in the container"
  echo "     <cmd> : execute any command directly"
fi

CONTAINER=$1
SERVICE=$(echo $CONTAINER | grep -o -e '^[^0-9]*')

if [ "$#" == "1" ]; then
  ACTION=bash
else
  shift
  ACTION=$*

  if [ "$SERVICE" == "cassandra" ]; then
    LOG=/var/log/cassandra/system.log
  elif [ "$SERVICE" == "elasticsearch" ]; then
    LOG=/var/log/elasticsearch/coscale.log
  elif [ "$SERVICE" == "postgresql" ]; then
    LOG=/var/log/postgresql/postgresql-9.3-main.log
  elif [ "$SERVICE" == "memcached" ]; then
    LOG=/var/log/memcached.log
  elif [ "$SERVICE" == "rabbitmq" ]; then
    LOG=/var/log/rabbitmq/rabbit*.log
  elif [ "$SERVICE" == "rum" ]; then
    LOG=/var/log/nginx/*.log
  elif [ "$SERVICE" == "streamingroller" ]; then
    DOCKER_LOGS=true
  elif [ "$SERVICE" == "streamingrollerwriteback" ]; then
    DOCKER_LOGS=true
  elif [ "$SERVICE" == "streamingtriggermatcher" ]; then
    DOCKER_LOGS=true
  elif [ "$SERVICE" == "anomalyaggregator" ]; then
    DOCKER_LOGS=true
  elif [ "$SERVICE" == "anomalydetector" ]; then
    DOCKER_LOGS=true
  elif [ "$SERVICE" == "kafka" ]; then
    DOCKER_LOGS=true
  elif [ "$SERVICE" == "zookeeper" ]; then
    DOCKER_LOGS=true
  else
    LOG=/var/log/$SERVICE/current
  fi

  if [ "$ACTION" == "log" ] && [ "$DOCKER_LOGS" != "true" ]; then
    ACTION="cat $LOG"
  elif [ "$ACTION" == "tail" ] && [ "$DOCKER_LOGS" != "true" ]; then
    ACTION="tail -f -n 100 $LOG"
  elif [ "$ACTION" == "jstack" ]; then
    ACTION='jstack `ps aux | grep java | grep -v grep | awk '"'"'{ print $2; }'"'"'`'
  fi
fi

if [ "$SERVICE" == "postgresql" ] && [ "$1" == "psql" ]; then
  docker exec -it coscale_$CONTAINER /bin/bash -c "PGPASSWORD=coscale psql -h localhost -U coscale -d app"
elif [ "$ACTION" == "log" ]; then
  docker logs coscale_$CONTAINER
elif [ "$ACTION" == "tail" ]; then
  docker logs -f --tail 100 coscale_$CONTAINER
else
  docker exec -it coscale_$CONTAINER /bin/bash -c "export TERM=xterm && $ACTION"
fi
