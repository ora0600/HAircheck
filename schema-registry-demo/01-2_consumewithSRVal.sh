#!/bin/bash

# set titke
export PROMPT_COMMAND='echo -ne "\033]0;Consume from Topic ${1} Normal\007"'
echo -e "\033];Consume from Topic ${1}  Normal\007"

#consume terminal 2
echo "consume from topic ${1}:"
kafka-avro-console-consumer --bootstrap-server localhost:9092 --topic ${1} --property schema.registry.url=http://localhost:8081
 