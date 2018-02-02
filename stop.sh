
#!/bin/bash -e

source conf.sh
source services.sh

NAME=${1:-all}

if [ "$NAME" == "--help" ]; then
    echo "$0 : stop all services."
    echo "$0 <service> : stop a specific service."
    echo "$0 coscale : stop the CoScale services."
    exit 0
fi

# Services which handle the SIGTERM well and shutdown themselves asap -> They get a higher timeout
# in case they have some work to do for a proper shutdown.  
COOPERATIVE_SERVICES="kafka zookeeper"

function stop {
    SERVICE=$1

    if [[ "$COOPERATIVE_SERVICES" == *"$SERVICE"* ]]; then
        echo "Stopping $SERVICE with large timeout";
        docker stop --time 1000 coscale_$SERVICE || echo "(Container not running)";
    else
        echo "Stopping $SERVICE with default timeout";
        docker stop coscale_$SERVICE || echo "(Container not running)";
    fi

    docker rm coscale_$SERVICE || echo "(Container not present)"
}

# Stop the deprecated services
for SERVICE in $DEPRECATED_SERVICES; do
    if [ "$NAME" == "all" ] || [ "$NAME" == "coscale" ] || [ "$NAME" == "data" ]; then
        # Don't bother when service is not running 
        if [ "$(docker ps -a | grep coscale_$SERVICE)" ]; then
            echo "Service $SERVICE is deprecated, stopping it..."
            stop $SERVICE
        fi
    fi
done

# Stop the data services
for SERVICE in $DATA_SERVICES; do
    if [ "$NAME" == "all" ] || [ "$NAME" == "data" ] || [ "$NAME" == "$SERVICE" ]; then
        stop $SERVICE
    fi
done

# Stop the coscale services
for SERVICE in $COSCALE_SERVICES $LB_SERVICE; do
    if [ "$NAME" == "all" ] || [ "$NAME" == "coscale" ] || [ "$NAME" == "$SERVICE" ]; then
        stop $SERVICE
    fi
done
