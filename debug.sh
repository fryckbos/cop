#!/bin/bash -e

source conf.sh
source services.sh

NAME=${1:-all}

if [ "$NAME" == "--help" ]; then
    echo "$0 : debug all services."
    echo "$0 <service> : debug a specific service."
    echo "$0 coscale : debug the CoScale services."
    exit 0
fi

# Create main debug directory if it doesn't exist
mkdir -p debug/

# Create current debug directory
DATE=$(date +%Y_%m_%d_%H%M%S)
DIR="debug/$DATE"
mkdir -p "$DIR"

function debug {
    DIR=$1
    SERVICE=$2

    # Create directory for service
    mkdir -p "$DIR/$SERVICE"

    # Output internal logs to dir
    ./connect.sh $SERVICE log > "$DIR/$SERVICE/log_internal" || true

    # Output docker logs to dir
    docker logs coscale_$SERVICE > "$DIR/$SERVICE/log_docker" || true

    # Output docker inspect to dir
    docker inspect coscale_$SERVICE > "$DIR/$SERVICE/inspect" || true
}

# Stop the data services
for SERVICE in $DATA_SERVICES; do
    if [ "$NAME" == "all" ] || [ "$NAME" == "data" ] || [ "$NAME" == "$SERVICE" ]; then
        debug $DIR $SERVICE
    fi
done

# Stop the coscale services
for SERVICE in $COSCALE_SERVICES $LB_SERVICE; do
    if [ "$NAME" == "all" ] || [ "$NAME" == "coscale" ] || [ "$NAME" == "$SERVICE" ]; then
        debug $DIR $SERVICE
    fi
done

# Output docker information
docker info > "$DIR/docker_info"
docker version > "$DIR/docker_version"
docker ps -a > "$DIR/docker_ps"

# Output current location to see on which disk we are
pwd > "$DIR/pwd"

# Output disk space available
df -h > "$DIR/df"

# Output memory available
free -m > "$DIR/free"

# Output version 
echo $VERSION > "$DIR/version"

# Tar the directory and remove 
tar -zcvf "$DATE.tar.gz" "$DIR"
rm -rf "$DIR"
