#!/bin/bash

###### set environment variables
# CCloud environment CMWORKSHOPS, have to be created before
source env-vars
# CCloud environment CMWORKSHOPS
CCLOUD_CLUSTERID1=$(awk '/id:/{print $NF}' clusterid1)
CCLOUD_CLUSTERID1_BOOTSTRAP=$(awk '/endpoint: SASL_SSL:\/\//{print $NF}' clusterid1 | sed 's/SASL_SSL:\/\///g')
CCLOUD_CLUSTERID2=$(awk '/id:/{print $NF}' clusterid2)
CCLOUD_CLUSTERID2_BOOTSTRAP=$(awk '/endpoint: SASL_SSL:\/\//{print $NF}' clusterid2 | sed 's/SASL_SSL:\/\///g')
CCLOUD_KEY1=$(awk '/key/{print $NF}' apikey1)
CCLOUD_KEY2=$(awk '/key/{print $NF}' apikey2)
CCLOUD_SRKEY=$(awk '/key/{print $NF}' srkey)

# drop topic in ccloud
kafka-topics --delete --bootstrap-server $CCLOUD_CLUSTERID1_BOOTSTRAP --topic cmorders_avro --command-config ./ccloud_user1.properties 
kafka-topics --delete --bootstrap-server $CCLOUD_CLUSTERID2_BOOTSTRAP --topic cmorders_avro --command-config ./ccloud_user2.properties 

# DELETE CCLOUD cluster 
confluent login
# environment CMWorkshops
confluent environment use $XX_CCLOUD_ENV

# delete API Key
confluent api-key delete $CCLOUD_KEY1
confluent api-key delete $CCLOUD_KEY2
confluent api-key delete $CCLOUD_SRKEY

# Delete cluster
confluent kafka cluster delete $CCLOUD_CLUSTERID1
confluent kafka cluster delete $CCLOUD_CLUSTERID2

# Delete files
rm apikey1
rm apikey2
rm basedir
rm ccloud_user1.properties
rm ccloud_user2.properties
rm clusterid1
rm clusterid2
rm connect-avro_distributed.properties
rm replicator_avro.json
rm srinfos
rm srkey
# Finish
echo "Clusters SOURCE and TARGET dropped"