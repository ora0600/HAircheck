#!/bin/bash

echo "clean cluster"
echo "drop topics"
kafka-topics --delete --bootstrap-server localhost:9092  --topic testtopic 
kafka-topics --delete --bootstrap-server localhost:9092  --topic SRVal-topic

rm basedir

echo "Stop Confluent Platform"
echo "confluent local services Stop"
confluent local services stop
echo "confluent local destroy"
confluent local destroy
