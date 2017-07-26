#!/bin/bash -e
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <service> [action]"
  echo "   action"
  echo "     bash : starts an interactive bash console (default)"
  echo "     log : get the full service log"
  echo "     tail : get a tailf of the service log"
  echo "     <cmd> : execute any command directly"
fi

SERVICE=$1

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
  else
    LOG=/var/log/$SERVICE/current
  fi

  if [ "$ACTION" == "log" ]; then
    ACTION="cat $LOG"
  elif [ "$ACTION" == "tail" ]; then
    ACTION="tail -f -n 100 $LOG"
  fi
fi



if [ "$SERVICE" == "postgresql" ] && [ "$1" == "migrate" ]; then
  cat $2 | docker exec -i coscale_$SERVICE /bin/bash -c "export TERM=xterm && migrate"
else
  docker exec -it coscale_$SERVICE /bin/bash -c "export TERM=xterm && $ACTION"
fi

