#!/bin/bash

SERVICE=$1

if [ "$SERVICE" == "" ]; then
  echo "Usage : $0 [<SERVICE>/all/coscale/data]"
elif [ "$SERVICE" == "agent-builder" ]; then
  echo "upgrading agent-builder"
  ./stop.sh haproxy && ./stop.sh api && ./run.sh api && ./connect.sh api /opt/coscale/agent-builder/update.sh && ./stop.sh api && ./run.sh api && ./run.sh haproxy
elif [ "$SERVICE" == "all" ]; then
  ./stop.sh && ./run.sh
elif [ "$SERVICE" == "coscale" ]; then
  ./stop.sh coscale && ./run.sh coscale
elif [ "$SERVICE" == "data" ]; then
  ./stop.sh data && ./run.sh data
else
  echo "upgrading service"
  ./stop.sh $1 && ./run.sh $1
fi
