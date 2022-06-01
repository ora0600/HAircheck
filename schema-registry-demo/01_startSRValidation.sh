#!/bin/bash

pwd > basedir
export BASEDIR=$(cat basedir)
echo $BASEDIR

export SRTOPIC=SRVal-topic
export TOPIC=testtopic

echo "Start Confluent Platform on your Mac"
confluent local services start
# Create SR validation topic
echo "Create Topic SRVal-topic with SR validation enabled"
kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1 --topic $SRTOPIC --config confluent.value.schema.validation=true

echo "Create Topic testtopic without SR validation enabled"
kafka-topics --create --bootstrap-server localhost:9092 --replication-factor 1 --partitions 1 --topic $TOPIC 

# run Apple script in iTerm to produce and consume
echo "run Apple Script and produce and consume without SR Validation"
echo "PRESS enter"
read
open -a iterm
echo "wait 10 secs..."
sleep 10
osascript 01_producewithSRVal.scpt $BASEDIR $TOPIC

echo "run Apple Script and produce and consume with SR Validation"
echo "PRESS enter"
read
open -a iterm
echo "wait 10 secs..."
sleep 10
osascript 01_producewithSRVal.scpt $BASEDIR $SRTOPIC

