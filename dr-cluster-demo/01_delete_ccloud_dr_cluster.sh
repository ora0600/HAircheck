#!/bin/bash

export CLUSTERID1KEY=$(awk '/key:/{print $NF}' clusterid1_key)
export CLUSTERID1SECRET=$(awk '/secret:/{print $NF}' clusterid1_key )
export CLUSTERID2KEY=$(awk '/key:/{print $NF}' clusterid2_key)
export CLUSTERID2SECRET=$(awk '/secret:/{print $NF}' clusterid2_key )
export CCLOUD_CLUSTERID2_BOOTSTRAP=$(awk '/endpoint: SASL_SSL:\/\//{print $NF}' clusterid2 | sed 's/SASL_SSL:\/\///g')
export CCLOUD_CLUSTERID1=$(awk '/id:/{print $NF}' clusterid1)
export CCLOUD_CLUSTERID1_BOOTSTRAP=$(awk '/endpoint: SASL_SSL:\/\//{print $NF}' clusterid1 | sed 's/SASL_SSL:\/\///g')
export CCLOUD_CLUSTERID2=$(awk '/id:/{print $NF}' clusterid2)
export ENVID=$(awk '/id:/{print $NF}' env)
export environment=$ENVID
export source_id=$CCLOUD_CLUSTERID1
export source_endpoint=$CCLOUD_CLUSTERID1_BOOTSTRAP
export sourcekey=$CLUSTERID1KEY
export sourcesecret=$CLUSTERID1SECRET
export destination_id=$CCLOUD_CLUSTERID2
export destination_endpoint=$CCLOUD_CLUSTERID2_BOOTSTRAP
export destinationkey=$CLUSTERID2KEY
export destinationsecret=$CLUSTERID2SECRET
export user1id=$(awk '/id:/{print $NF}' user1)

export topic2=project.b1.inventory
export user1key=$(awk '/key/{print $NF}' apikeyuser1)
export user1secret=$(awk '/secret/{print $NF}' apikeyuser1)
export topic1=project.a1.orders
export user2id=$(awk '/id:/{print $NF}' user2)
export user2key=$(awk '/key/{print $NF}' apikeyuser2)
export user2secret=$(awk '/secret/{print $NF}' apikeyuser2)

echo "delete verything form this demo"
echo "destination cluster"
# delete topics in destination
confluent kafka topic delete $topic1 --cluster $destination_id --environment $environment 
confluent kafka topic delete $topic2 --cluster $destination_id --environment $environment 
# drop cluster link
confluent kafka link delete my-link --cluster $destination_id --environment $environment
confluent kafka cluster delete $destination_id --environment $environment

echo "ACLS"
confluent kafka acl delete --allow --service-account $user1id --operation CREATE  --topic $topic1 --prefix  --cluster $source_id
confluent kafka acl delete --allow --service-account $user1id --operation WRITE --topic $topic1 --prefix --cluster $source_id
confluent kafka acl delete --allow --service-account $user1id --operation READ --topic $topic1 --prefix --cluster $source_id
confluent kafka acl delete --allow --service-account $user1id --operation READ --consumer-group $topic1 --prefix --cluster $source_id

confluent kafka acl delete --allow --service-account $user2id --operation CREATE  --topic $topic2 --prefix  --cluster $source_id
confluent kafka acl delete --allow --service-account $user2id --operation WRITE --topic $topic2 --prefix --cluster $source_id
confluent kafka acl delete --allow --service-account $user2id --operation READ --topic $topic2 --prefix --cluster $source_id
confluent kafka acl delete --allow --service-account $user2id --operation READ --consumer-group $topic2 --prefix --cluster $source_id

echo "Source cluster"
confluent kafka topic delete $topic1 --cluster $source_id --environment $environment 
confluent kafka topic delete $topic2 --cluster $source_id --environment $environment 
confluent kafka cluster delete $source_id --environment $environment

echo "API Keys"
confluent api-key delete $user1key
confluent api-key delete $user2key

echo "service accounts"
confluent iam service-account delete $user1id
confluent iam service-account delete $user2id

echo "environment"
confluent environment delete $environment

echo "files"
rm apikeyuser1
rm apikeyuser2
rm clusterid1
rm clusterid1_key
rm clusterid2
rm clusterid2_key
rm destination-link.config
rm dr-link.config
rm dr-link2.config
rm env
rm link-configs.properties
rm source-link.config
rm user1
rm user2

echo "Demo Environment deleted"