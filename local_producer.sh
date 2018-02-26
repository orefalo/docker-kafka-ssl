#!/bin/bash
kafka-console-producer --broker-list kafka+ssl://kafka.docker.ssl:9094 --topic test --producer.config ./local_client_ssl.properties
