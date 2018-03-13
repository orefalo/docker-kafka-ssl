#!/bin/bash

KAFKA_PORT=9094

CONTAINERS=$(docker ps | grep $KAFKA_PORT | awk '{print $1}')
BROKERS=$(for CONTAINER in ${CONTAINERS}; do docker port "$CONTAINER" $KAFKA_PORT | sed -e "s/0.0.0.0:/$HOST_IP:/g"; done)
echo "${BROKERS/$'\n'/,}"