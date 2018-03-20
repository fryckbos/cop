#!/bin/bash

# Change working directory
cd `dirname $0`

# Load configuration and services
source conf.sh
source services.sh

function usage {
    echo "$0 [-urtq] <action>"
    echo ""
    echo "Flags"
    echo "    -u                upload the data to CoScale opdebug"
    echo "    -r                remove file after upload"
    echo "    -t                use timestamped filenames"
    echo "    -q                quiet mode"
    echo ""
    echo "Actions"
    echo "    test-https        test whether the HTTPS certificates are properly configured"
    echo "    test-email [recipient-email]"
    echo "                      test sending an email with the provided configuration"
    echo ""
    echo "    version           print the currently running CoScale version"
    echo "    system            create a sytem diagnostics package (system.tgz)"
    echo "    check-services    check whether all services are running"
    echo "    list-services     shows the list of configured services"
    echo "    inspect-service [service]"
    echo "                      create a diagnostics package for a service (service.tgz)"
    echo "    log-dump [hours]  create a log dump for the last x hours for all services (logs.tgz)"
    echo "    backup            create a PostgreSQL backup (backup.tgz)"
    echo ""
    echo "    start-logger      start a diagnostics container that uploads the logs once every hour"
    echo "    stop-logger       stop the logger diagnostics container"
    echo ""
    echo "    htop              execute htop"
    echo "    clean-images      remove unused CoScale images from Docker"
    echo "    get-certs [host:port]"
    echo "                      get SSL certificates for service running on host:port"
    echo ""
    echo "    kafka <action>    get more information about the kafka state"
    exit 0
}

LOGGER_NAME=oplogger

function info {
    if [ "$QUIET" == "false" ]; then
        echo "$1"
    fi
}

function get_filename {
    if [ "$USE_TIMESTAMP" == "false" ]; then
        echo ${1}.${2}
    else
        TS=$(date +%Y_%m_%d_%H%M%S)
        echo ${1}-${TS}.${2}
    fi
}

function upload {
    if [ "$UPLOAD" == "true" ]; then
        info ""
        info "Uploading $1..."
        ./upload.sh $1
        if [ "$REMOVE_FILE" == "true" ]; then
            info "Removing $1..."
            rm $1
        fi
        info "Done uploading"
    fi
}

function version {
    IMAGES=$(for SERVICE in $COSCALE_SERVICES; do docker inspect --format='{{.Config.Image}}' coscale_${SERVICE}; done)
    VERSION=$(echo "$IMAGES" | awk -F: '{ print $2; }' | uniq)

    if [ $(echo "$VERSION" | wc -l) == "1" ]; then
        info "$VERSION"
        exit 0
    else
        info "Not all components are on the same version"
        info
        info "$IMAGES"
        exit 1
    fi
}

function system {
    info "Gathering system diagnostics..."
    DIR=system
    mkdir -p $DIR

    # Output docker information
    docker info > "$DIR/docker_info" 2>&1
    docker version > "$DIR/docker_version" 2>&1
    docker ps -a > "$DIR/docker_ps" 2>&1

    # Output current location to see on which disk we are
    pwd > "$DIR/pwd"

    # Output disk space available
    df -h > "$DIR/df"

    # Output memory, load, cpus, processes on the system
    free -m > "$DIR/free"
    uptime > "$DIR/uptime"
    cat /proc/cpuinfo > "$DIR/cpu"
    ps auxf > "$DIR/ps"

    # Output CoScale version
    echo $VERSION > "$DIR/coscale_version"

    # Create archive
    FILENAME=$(get_filename system tgz)
    tar czf $FILENAME $DIR
    rm -Rf $DIR

    info "Diagnostics are ready in $FILENAME"
    upload $FILENAME
}

function do_inspect {
    DIR=$1
    SERVICE=$2

    info "  Processing $SERVICE"

    # Create directory for service
    mkdir -p "$DIR/$SERVICE"

    # Output internal logs to dir
    ./connect.sh $SERVICE log > "$DIR/$SERVICE/log_internal" 2>&1

    # Output docker logs to dir
    docker logs coscale_$SERVICE > "$DIR/$SERVICE/log_docker" 2>&1

    # Output docker inspect to dir
    docker inspect coscale_$SERVICE > "$DIR/$SERVICE/inspect" 2>&1
}

function inspect_service {
    NAME=$1

    info "Gathering service information for $NAME..."
    DIR=service
    mkdir -p $DIR

    # Loop the data services to gather information
    for SERVICE in $DATA_SERVICES; do
        if [ "$NAME" == "all" ] || [ "$NAME" == "data" ] || [ "$NAME" == "$SERVICE" ]; then
            do_inspect $DIR $SERVICE
        fi
    done

    # Loop the coscale services to gather information
    for SERVICE in $COSCALE_SERVICES $LB_SERVICE; do
        if [ "$NAME" == "all" ] || [ "$NAME" == "coscale" ] || [ "$NAME" == "$SERVICE" ]; then
            do_inspect $DIR $SERVICE
        fi
    done

    # Create archive
    FILENAME=$(get_filename service tgz)
    tar czf $FILENAME $DIR
    rm -Rf $DIR

    info "Service info is ready in $FILENAME"
    upload $FILENAME
}

function check_services {
    DOWN=0
    SERVICES_DOWN=""

    for SERVICE in $DATA_SERVICES $COSCALE_SERVICES $LB_SERVICE; do
        OUTPUT=`docker inspect -f {{.State.Running}} coscale_$SERVICE 2>/dev/null`
        if [ "$?" == "1" -o "$OUTPUT" == "false" ]; then
            DOWN=1
            SERVICES_DOWN="$SERVICE $SERVICES_DOWN"
        fi
    done

    FILENAME=$(get_filename services txt)

    if [ "$DOWN" == "0" ]; then
        echo "All services are running." | tee $FILENAME
    else
        echo "The following services are down: $SERVICES_DOWN" | tee $FILENAME
    fi

    upload $FILENAME
    exit $DOWN
}

function list_services {
    info "export DATA_SERVICES=\"$DATA_SERVICES\""
    info "export LB_SERVICE=\"$LB_SERVICE\""
    info "export COSCALE_SERVICES=\"$COSCALE_SERVICES\""
    info "export DEPRECATED_SERVICES=\"$DEPRECATED_SERVICES\""
}

function test_https {
    # Check if the environment variable is set and the certificate is present
    if docker ps | grep coscale_haproxy >/dev/null; then
        echo "Error: stop haproxy before performing test-https (./stop.sh haproxy)"
        exit 1
    fi

    if [ "$ENABLE_HTTPS" != "1" ]; then
        echo "Error: set ENABLE_HTTPS to 1 in conf.sh"
        exit 1
    fi

    if [ ! -e data/ssl/https.pem ]; then
        echo "Error: HTTPS is enabled but data/ssl/https.pem does not exist"
        exit 1
    fi

    if ! grep 'BEGIN CERTIFICATE' data/ssl/https.pem >/dev/null; then
        echo "Error: could not find BEGIN CERTIFICATE in data/ssl/https.pem"
        exit 1
    fi

    if ! grep 'END CERTIFICATE' data/ssl/https.pem >/dev/null; then
        echo "Error: could not find END CERTIFICATE in data/ssl/https.pem"
        exit 1
    fi

    if ! grep 'BEGIN .*PRIVATE KEY' data/ssl/https.pem >/dev/null; then
        echo "Error: could not find BEGIN PRIVATE KEY in data/ssl/https.pem"
        exit 1
    fi

    if ! grep 'END .*PRIVATE KEY' data/ssl/https.pem >/dev/null; then
        echo "Error: could not find END CERTIFICATE in data/ssl/https.pem"
        exit 1
    fi

    # Start a HaProxy container (+ backend) with the HTTPS certificate
    docker run -d --name coscale_test_https_backend coscale/rum:$VERSION >/dev/null

    docker run -d \
        -v `pwd`/data/ssl:/data/ssl:Z \
        -e "ENABLE_HTTPS=$ENABLE_HTTPS" \
        --link coscale_test_https_backend:api \
        --link coscale_test_https_backend:app \
        --link coscale_test_https_backend:rum \
        --link coscale_test_https_backend:rumdatareceiver \
        -p 0.0.0.0:443:443 \
        --name coscale_test_https_haproxy coscale/haproxy:$VERSION >/dev/null

    # Check whether a curl works
    CURL_OPTS=""
    if [ -e data/ssl/selfsigned.crt ]; then
        CURL_OPTS="--cacert /data/ssl/selfsigned.crt"
    fi

    docker exec coscale_test_https_haproxy /bin/bash -c "curl $CURL_OPTS $API_URL >/dev/null"
    CURL_STATUS=$?

    # Stop and remove the containers
    docker rm -f coscale_test_https_backend coscale_test_https_haproxy >/dev/null
    echo

    if [ "$CURL_STATUS" == "0" ]; then
        echo "HTTPS is properly configured !"
        exit 0
    else
        echo "Error: HTTPS is not properly configured. (curl failed with $CURL_STATUS)"
        exit $CURL_STATUS
    fi
}

function test_email {
    RECIPIENT=$1

    docker run --rm -it \
        -v `pwd`/data/ssl:/data/ssl:Z \
        -e "MAIL_SERVER=$MAIL_SERVER" \
        -e "MAIL_PORT=$MAIL_PORT" \
        -e "MAIL_SSL=$MAIL_SSL" \
        -e "MAIL_TLS=$MAIL_TLS" \
        -e "MAIL_AUTH=$MAIL_AUTH" \
        -e "MAIL_USERNAME=$MAIL_USERNAME" \
        -e "MAIL_PASSWORD=$MAIL_PASSWORD" \
        -e "FROM_EMAIL=$FROM_EMAIL" \
        --name coscale_test_mailer coscale/mailer:$VERSION \
        /bin/bash -c "/entrypoint.sh --test $RECIPIENT"
}

function do_htop {
    if [ "$UPLOAD" == "true" ]; then
        FILENAME=$(get_filename htop html)
        docker run --pid=host -it coscale/diag ./htop.sh > $FILENAME
        upload $FILENAME
    else
        docker run --pid=host -it coscale/diag htop
    fi
}

function get_logs {
    HOURS=$1
    MINUTES=$(($HOURS * 60))
    info "Gathering logs for $HOURS hours..."

    mkdir -p logs

    # Get the service logs
    for SERVICE in $COSCALE_SERVICES $LB_SERVICE; do
        info "  Processing $SERVICE"
        DIR=/var/log/$SERVICE
        docker exec coscale_$SERVICE /bin/bash -c 'if [ -e '"$DIR"' ]; then cd '"$DIR"'; tar czf /logs.tgz `find . -cmin -'"$MINUTES"'`; else exit 1; fi'
        if [ "$?" -eq "0" ]; then
            docker cp coscale_$SERVICE:/logs.tgz logs/${SERVICE}-logs.tgz
            docker exec coscale_$SERVICE /bin/bash -c 'rm /logs.tgz'
        fi
    done

    # Get the agent logs
    BATCH=10000
    OFFSET=0
    AGENT_LOGFILE=agent.log

    for i in `seq 10`; do
        info "Retrieving $BATCH agent logs at offset $OFFSET..."
        docker exec coscale_elasticsearch /bin/bash -c 'curl -s -XGET "http://localhost:9200/agent/_search?pretty&from='$OFFSET'&size='$BATCH'" -d "{\"query\":{\"range\":{\"_timestamp\":{\"gte\":\"now-'$HOURS'h\",\"lte\":\"now\"}}}}"' > logs/$AGENT_LOGFILE.$i
        LINES=$(cat logs/$AGENT_LOGFILE.$i | wc -l)
        if [ $LINES -lt $(($BATCH * 5)) ]; then break; fi
        OFFSET=$(($OFFSET + $BATCH))
    done
    tar czf logs/agent-logs.tgz logs/$AGENT_LOGFILE.*
    rm logs/$AGENT_LOGFILE.*

    # Package it up
    FILENAME=$(get_filename logs tgz)
    tar czf $FILENAME logs
    rm -Rf logs
    info "Logs are ready in $FILENAME"

    upload $FILENAME
}

function do_backup {
    info "Creating database backup..."
    ./connect.sh postgresql 'sudo -u postgres pg_dump global' > global.sql
    ./connect.sh postgresql 'sudo -u postgres pg_dump app' > app.sql

    FILENAME=$(get_filename backup tgz)
    tar czf $FILENAME global.sql app.sql
    rm global.sql app.sql
    info "Backup is ready in $FILENAME"

    upload $FILENAME
}

function start_logger {
    info "Starting logger container"

    docker run -d \
        -v `pwd`:/coscale:Z \
        -v /var/run/docker.sock:/var/run/docker.sock \
        --net=host --pid=host \
        --restart unless-stopped \
        -e "HTTP_PROXY=$HTTP_PROXY" \
        -e "HTTPS_PROXY=$HTTPS_PROXY" \
        --name coscale_${LOGGER_NAME} coscale/diag /opt/coscale/logger.sh 1
}

function stop_logger {
    info "Stopping logger container"
    docker stop coscale_${LOGGER_NAME} || echo "(Container not running)"
    docker rm coscale_${LOGGER_NAME} || echo "(Container not present)"
}

function clean_images {
    info "Removing unused CoScale images from Docker"
    docker images | grep 'coscale/' | grep -v "$VERSION" | grep -v "latest" | awk '{ print $3; }' | xargs -n1 docker rmi -f 2>/dev/null
}

function get_certs {
    HOST=$1
    info "Getting certificates for $HOST"
    docker run --rm -it coscale/diag /opt/coscale/get-certs.sh $HOST
}

function kafka {
    ACTION=${1:-help}
    shift

    if [ "$ACTION" == "list-consumer-groups" ]; then
        ./connect.sh kafka kafka-consumer-groups --bootstrap-server localhost:9092 --list
    elif [ "$ACTION" == "describe-consumer-group" ]; then
        GROUP=$1
        ./connect.sh kafka kafka-consumer-groups --bootstrap-server localhost:9092 --describe --group $GROUP
    elif [ "$ACTION" == "consumer-group-seek-to-end" ]; then
        GROUP=$1
        ./connect.sh kafka kafka-consumer-groups --bootstrap-server localhost:9092 --reset-offsets --to-latest --execute --all-topics --group $GROUP
    elif [ "$ACTION" == "list-topics" ]; then
        ./connect.sh kafka kafka-topics --zookeeper zookeeper:32181 --list
    elif [ "$ACTION" == "log-topics" ]; then
        docker run -it --rm --link coscale_kafka:kafka coscale/streamingroller:$VERSION java -cp /opt/coscale/streamingroller/bin/streamingroller-$VERSION-jar-with-dependencies.jar coscale.streamingcore.kafka.LogTopics -h kafka:9092 $@
    elif [ "$ACTION" == "manage-topics" ]; then
        docker run -it --rm --link coscale_kafka:kafka coscale/streamingroller:$VERSION java -cp /opt/coscale/streamingroller/bin/streamingroller-$VERSION-jar-with-dependencies.jar coscale.streamingcore.kafka.ManageTopics -h kafka:9092 $@
    elif [ "$ACTION" == "describe-topic" ]; then
        TOPIC=$1
        ./connect.sh kafka kafka-topics --zookeeper zookeeper:32181 --describe --topic $TOPIC
    elif [ "$ACTION" == "delete-topic" ]; then
        TOPIC=$1
        ./connect.sh kafka kafka-topics --zookeeper zookeeper:32181 --delete --topic $TOPIC
    elif [ "$ACTION" == "changelogsize" ]; then
        find 'data/kafka/data' -regex '.*changelog.*' -print0 | du --files0-from=- -ch | sort -h
    else
        kafka_usage
    fi
}

function kafka_usage {
    echo "$0 [-urtq] kafka <action>"
    echo ""
    echo "Flags"
    echo "    -u                upload the data to CoScale opdebug"
    echo "    -r                remove file after upload"
    echo "    -t                use timestamped filenames"
    echo "    -q                quiet mode"
    echo ""
    echo "Kafka actions"
    echo "    list-consumer-groups                list all kafka consumer groups"
    echo "    describe-consumer-group [group]     describe a kafka consumer group"
    echo "    consumer-group-seek-to-end [group]  seek to the end of all partitions on all topics for the specified consumer group"
    echo ""
    echo "    list-topics              list all kafka topics" 
    echo "    log-topics [opts]        view a live stream of messages on a topic"
    echo "    manage-topics [opts]     create or update configurations of topics"
    echo "    describe-topic [topic]   describe a kafka topic"
    echo "    delete-topic [topic]     delete a kafka topic"
    echo ""
    echo "    changelogsize            get the total changelog size"
    exit 0
}


# Parse command line arguments
UPLOAD=false
USE_TIMESTAMP=false
QUIET=false
REMOVE_FILE=false

while getopts "utqr" ARG; do
  case $ARG in
    u) UPLOAD=true ;;
    t) USE_TIMESTAMP=true ;;
    q) QUIET=true ;;
    r) REMOVE_FILE=true ;;
  esac
done

shift $((OPTIND-1))

# Execute the requested action
ACTION=${1:-help}

if [ "$ACTION" == "version" ]; then
    version
elif [ "$ACTION" == "system" ]; then
    system
elif [ "$ACTION" == "check-services" ]; then
    check_services
elif [ "$ACTION" == "list-services" ]; then
    list_services
elif [ "$ACTION" == "test-https" ]; then
    test_https
elif [ "$ACTION" == "test-email" ]; then
    RECIPIENT=$2
    test_email $RECIPIENT
elif [ "$ACTION" == "inspect-service" ]; then
    SERVICE=${2:-all}
    inspect_service $SERVICE
elif [ "$ACTION" == "htop" ]; then
    do_htop
elif [ "$ACTION" == "log-dump" ]; then
    HOURS=${2:-24}
    get_logs $HOURS
elif [ "$ACTION" == "backup" ]; then
    do_backup
elif [ "$ACTION" == "start-logger" ]; then
    start_logger
elif [ "$ACTION" == "stop-logger" ]; then
    stop_logger
elif [ "$ACTION" == "clean-images" ]; then
    clean_images
elif [ "$ACTION" == "get-certs" ]; then
    HOST=$2
    get_certs $HOST
elif [ "$ACTION" == "kafka" ]; then
    shift
    kafka $@
else
    usage
fi
