###TEST###

./custom-run.sh dns 001

#for app to work
# ./custom-updatens.sh sea.coscale.com 52.230.31.196

./custom-run.sh cassandra 001

#sets master cname in custom-rabbitmq001.conf
./custom-run.sh rabbitmq 001

#sets master cname in custom-memcached001.conf
./custom-run.sh memcached 001

./custom-run.sh elasticsearch 001

#sets postgresql-master cname in custom-postgresql001.conf
#sets postgresql cname in custom-postgresql001.conf (for migrations script)
./custom-run.sh postgresql 001

#sets COSCALE_WORKERS_QUEUE=rabbitmq-master
#sets COSCALE_CASSANDRA_CLUSTER_HOSTS=cassandra001:9042
./custom-run.sh datastore 001
./custom-run.sh datastore 002

#sets memcached-master and rabbitmq-master in custom
./custom-run.sh app 001

#sets memcached-master and rabbitmq-master in custom
./custom-run.sh api 001
./custom-run.sh api 002

#sets rumdatareceiver cname in custom-rumdatareceiver001.conf (for haproxy conf)
#RUNNING FINE - setting : rabbitmq-master
./custom-run.sh rumdatareceiver 001

#serving the snippet works ok
./custom-run.sh rum 001

#HERE there is manual editing required in the config (add api001,api002)
#and it won't start if the hosts are unknown
#so as workaround we have to make temporary cnames
./custom-setcname.sh api.sea.coscale.com api001.sea.coscale.com
./custom-setcname.sh app.sea.coscale.com app001.sea.coscale.com
./custom-run.sh haproxy 001


#RUNNING FINE - setting : rabbitmq-master
./custom-run.sh cron 001

#RUNNING FINE - setting : rabbitmq-master
./custom-run.sh roller 001

#RUNNING FINE - setting : rabbitmq-master
./custom-run.sh mailer 001

#RUNNING FINE - setting : rabbitmq-master
./custom-run.sh alerter 001

#RUNNING FINE - setting : rabbitmq-master
./custom-run.sh reporter 001

#RUNNING FINE - setting : rabbitmq-master
./custom-run.sh pageminer 001

#RUNNING FINE - setting : rabbitmq-master
./custom-run.sh anomalymatcher 001

#RUNNING FINE - setting : rabbitmq-master
./custom-run.sh analysismanager 001

#RUNNING FINE - setting : rabbitmq-master
./custom-run.sh anomalydetectorservice 001




