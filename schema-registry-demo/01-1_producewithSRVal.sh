#!/bin/bash


# Set title
export PROMPT_COMMAND='echo -ne "\033]0;Produce to Topic ${1} \007"'
echo -e "\033];Produce to Topic ${1}\007"

# produce to topic $1
echo "produce to Topic ${1} automatically "
for i in `seq 1 150`; do echo "{\"flight_id\":\"${i}\",\"flight_to\":\"QWE\",\"flight_from\":\"RTY\"}" | kafka-avro-console-producer --broker-list localhost:9092 --topic ${1} --property value.schema='{"type":"record","name":"schema","fields":[{"name":"flight_id","type":"string"},{"name":"flight_to", "type": "string"}, {"name":"flight_from", "type": "string"}]}' --property schema.registry.url=http://localhost:8081 ; date +%s; done