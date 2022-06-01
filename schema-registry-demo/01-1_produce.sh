#!/bin/bash


# Set title
export PROMPT_COMMAND='echo -ne "\033]0;Produce bad data to Topic ${1} \007"'
echo -e "\033];Produce bad data to Topic ${1}\007"

# produce to topic $1
echo "please enter the following bad values and see what is happening"
echo " :  bad values"
echo "ENTER values:"
kafka-console-producer --broker-list localhost:9092 --topic ${1} 
