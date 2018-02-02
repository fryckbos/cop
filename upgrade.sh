#!/bin/bash -e

VERSION=$1
SERVICES=${2:-coscale}

function section {
    echo
    echo "--- $1 ---"
    echo
}

section "Updating cop git repo"
git pull

section "Setting new version in conf.sh"
sed -i "s|VERSION=.*|VERSION=$VERSION|" conf.sh
echo "Set to version $VERSION"

section "Pulling docker images"
./pull.sh

section "Stopping $SERVICES services"
./stop.sh $SERVICES

if [ "$SERVICES" == "all" ]; then
    section "Starting data services"
    ./run.sh data
    sleep 30
fi

section "Create actions to update agents"
./run.sh api
./connect.sh api /opt/coscale/agent-builder/update.sh
./stop.sh api

section "Starting coscale services"
./run.sh coscale

section "Removing old coscale images"
set +e
./diagnose.sh clean-images >/dev/null 2>&1
echo "Done"
