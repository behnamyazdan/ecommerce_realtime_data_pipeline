#!/bin/sh

## Create the PostgreSQL connector
echo "Creating PostgreSQL connector..."
wget --quiet --tries=3 --output-document=/dev/null --post-file=/init-scripts/postgres-connector.json --header="Content-Type: application/json" http://debezium:8083/connectors

## if you want to use Curl:
#curl -X POST -H "Content-Type: application/json" \
#    --data @/init-scripts/postgres-connector.json http://debezium:8083/connectors


