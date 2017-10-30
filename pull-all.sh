#!/bin/bash 

source conf.sh

./pull.sh --version "$VERSION" rabbitmq
./pull.sh --version "$VERSION" memcached
./pull.sh --version "$VERSION" postgresql
./pull.sh --version "$VERSION" elasticsearch
./pull.sh --version "$TEST_VERSION" zookeeper
./pull.sh --version "$TEST_VERSION" kafka
./pull.sh --version "$VERSION" api
./pull.sh --version "$VERSION" app
./pull.sh --version "$VERSION" cron
./pull.sh --version "$VERSION" datastore
./pull.sh --version "$VERSION" rum
./pull.sh --version "$VERSION" rumdatareceiver
./pull.sh --version "$VERSION" rumaggregator
./pull.sh --version "$VERSION" haproxy
./pull.sh --version "$TEST_VERSION" streamingroller
./pull.sh --version "$TEST_VERSION" streamingrollerwriteback









