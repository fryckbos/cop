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

section "Create actions to update agents"
./run.sh api
./connect.sh api /opt/coscale/agent-builder/update.sh
./stop.sh api

section "Starting $SERVICES services"
./run.sh $SERVICES
