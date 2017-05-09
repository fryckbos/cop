#!/bin/bash

SERVICE=$1

if [ "$SERVICE" == "agent-builder" ]; then
  echo "upgrading agent-builder"
  ./stop.sh haproxy && ./stop.sh api && ./run.sh api && ./connect.sh api /opt/coscale/agent-builder/update.sh && ./stop.sh api && ./run.sh api && ./run.sh haproxy
else
  echo "upgrading service"
  ./stop.sh $1 && ./run.sh $1
fi


