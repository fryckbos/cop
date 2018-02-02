#!/bin/bash 

source conf.sh

./run.sh --version "$VERSION" rabbitmq
./run.sh --version "$VERSION" memcached
./run.sh --version "$VERSION" postgresql
./run.sh --version "$VERSION" elasticsearch

./run.sh --version "$TEST_VERSION" zookeeper

echo "Sleeping 10 s for having zookeeper run"
sleep 10

./run.sh --version "$TEST_VERSION" kafka

echo "Sleeping 10 s for having kafka run"
sleep 10

./run.sh --version "$VERSION" api
./run.sh --version "$VERSION" app
./run.sh --version "$VERSION" cron

./run.sh --version "$VERSION" datastore

./run.sh --version "$VERSION" rum
./run.sh --version "$VERSION" rumdatareceiver
./run.sh --version "$VERSION" rumaggregator

./run.sh --version "$VERSION" haproxy

./run.sh --version "$TEST_VERSION" streamingroller streamingroller-0
./run.sh --version "$TEST_VERSION" streamingroller streamingroller-1
./run.sh --version "$TEST_VERSION" streamingroller streamingroller-2
./run.sh --version "$TEST_VERSION" streamingroller streamingroller-3

./run.sh --version "$TEST_VERSION" streamingrollerwriteback

