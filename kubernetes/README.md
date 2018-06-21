# Running CoScale on Kubernetes

Requirements:

* Cassandra and Elasticsearch are running in a separate cluster. The data-cluster directory has a setup script to setup these clusters on docker hosts.
* PostgreSQL is running in a separated cluster. You can also use a hosted PostgreSQL solution like Amazon RDS.

## Configuration

    cat << EOF > services.override
    export DATA_SERVICES="rabbitmq memcached"
    export LB_SERVICE="haproxy"
    export COSCALE_SERVICES="alerter api app cron datastore mailer pageminer reporter anomalymatcher triggermatcher rum rumdatareceiver collector rumaggregator roller analysismanager anomalydetectorservice"
    EOF


Fill in the following values in conf.sh

    export USE_EXTERNAL_CASSANDRA=true
    export EXTERNAL_CASSANDRA_ENDPOINTS=data001:9042,data002:9042,data003:9042


Add extra configuration to conf.sh

    export ELASTICSEARCH_REGULAR_HOSTS=data001:9300,data002:9300,data003:9300
    export ELASTICSEARCH_ANOMALY_HOSTS=data001:9300,data002:9300,data003:9300

    export DB_DEFAULT_URL="jdbc:postgresql://<HOST>/app"
    export DB_DEFAULT_USER="<USERNAME>"
    export DB_DEFAULT_PASSWORD="<PASSWORD>"

    export DB_GLOBAL_URL="jdbc:postgresql://<HOST>/global"
    export DB_GLOBAL_USER="<USERNAME>"
    export DB_GLOBAL_PASSWORD="<PASSWORD>"

Important notes about the PostgreSQL connection
* The databases will be created by the init-ext-psql command
* The user needs database creation rights
* The names of the databases have to remain app and global
* The HOST has to be the same of both the app and global databases
* Add "?ssl=true" at the end of DB_DEFAULT_URL and DB_GLOBAL_URL to enable ssl

## Installation

    ../pull.sh
    ../diagnose.sh init-ext-psql
    ./setup.sh
