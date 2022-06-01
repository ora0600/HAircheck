#!/bin/bash
# Create DR Cluster Demo

# follow the steps https://docs.confluent.io/cloud/current/multi-cloud/cluster-linking/quickstart.html

pwd > basedir
export BASEDIR=$(cat basedir)
echo $BASEDIR

cd ~/Demos/SEServiceCatalog/HAircheck/dr-cluster-demo
export uuid=$(uuidgen)
export env=drcluster-$uuid
# create cluster source and env
confluent login
# Environments
echo "confluent environment create $env"
confluent environment create $env -o yaml > env
export ENVID=$(awk '/id:/{print $NF}' env)
echo $ENVID
# Clusters
confluent kafka cluster create sourcecluster --cloud 'gcp' --region 'europe-west1' --type basic --environment $ENVID -o yaml > clusterid1
confluent kafka cluster create drcluster --cloud 'aws' --region 'eu-central-1' --type dedicated --availability single-zone --cku 1 --environment $ENVID -o yaml > clusterid2
echo "clusters created wait 30 sec"
sleep 30
# set cluster id as parameter
export CCLOUD_CLUSTERID1=$(awk '/id:/{print $NF}' clusterid1)
export CCLOUD_CLUSTERID2=$(awk '/id:/{print $NF}' clusterid2)
echo "Wait for dedicated cluster created wait 30 minutes"
sleep 1800
echo "30 minutes are over, please check dedicated cluster is runing, then PRESS ENTER..."
read
confluent kafka cluster describe $CCLOUD_CLUSTERID2 --environment $ENVID -o yaml > clusterid2
export CCLOUD_CLUSTERID2_BOOTSTRAP=$(awk '/endpoint: SASL_SSL:\/\//{print $NF}' clusterid2 | sed 's/SASL_SSL:\/\///g')
confluent kafka cluster describe $CCLOUD_CLUSTERID1 --environment $ENVID -o yaml > clusterid1
export CCLOUD_CLUSTERID1_BOOTSTRAP=$(awk '/endpoint: SASL_SSL:\/\//{print $NF}' clusterid1 | sed 's/SASL_SSL:\/\///g')

# Create API Keys for Source cluster and destination cluster
confluent api-key create --resource $CCLOUD_CLUSTERID1 --description " Key for $CCLOUD_CLUSTERID1" --environment $ENVID -o yaml > clusterid1_key
confluent api-key create --resource $CCLOUD_CLUSTERID2 --description " Key for $CCLOUD_CLUSTERID2" --environment $ENVID -o yaml > clusterid2_key
export CLUSTERID1KEY=$(awk '/key:/{print $NF}' clusterid1_key)
export CLUSTERID1SECRET=$(awk '/secret:/{print $NF}' clusterid1_key )
export CLUSTERID2KEY=$(awk '/key:/{print $NF}' clusterid2_key)
export CLUSTERID2SECRET=$(awk '/secret:/{print $NF}' clusterid2_key )
echo "Source Key for source cluster"
cat clusterid1_key
echo "DR Key for DR cluster"
cat clusterid2_key
echo "API keys for clusters are created wait 30 sec..."
sleep 30

export environment=$ENVID
export source_id=$CCLOUD_CLUSTERID1
export source_endpoint=$CCLOUD_CLUSTERID1_BOOTSTRAP
export sourcekey=$CLUSTERID1KEY
export sourcesecret=$CLUSTERID1SECRET
export destination_id=$CCLOUD_CLUSTERID2
export destination_endpoint=$CCLOUD_CLUSTERID2_BOOTSTRAP
export destinationkey=$CLUSTERID2KEY
export destinationsecret=$CLUSTERID2SECRET

echo "clusters are created:$CCLOUD_CLUSTERID1 and $CCLOUD_CLUSTERID2"

# use created environment
confluent environment use $environment

echo ">>>>>>>>>>>> Start Setup of DR Cluster"

# First Topic
export topic1=project.a1.orders
echo "Start: create Topic $topic1 in source cluster with ACL and Service data and produce and consume data"
# Create topics
echo "  create topic"
confluent kafka topic create $topic1 --partitions 1 --environment $environment --cluster $source_id
# produce
echo "  produce data"
for i in `seq 1 10`; do echo $i | confluent kafka topic produce $topic1 --environment $environment --cluster $source_id --api-key $sourcekey; done
# consume
echo "  consume data"
confluent kafka topic consume $topic1 --from-beginning --environment $environment --cluster $source_id --api-key $sourcekey
# Create service account
echo "  create service account"
confluent iam service-account create "project.a1.user1" --description "project.a1.user1 can be deleted by Cmutzlitz" -o yaml> user1
export user1id=$(awk '/id:/{print $NF}' user1)
# Create service account key
echo "  create key for service account"
confluent api-key create --resource $source_id --service-account $user1id --description "API Key for Service Account ${user1id} project.a1.user1 " -o yaml > apikeyuser1
export user1key=$(awk '/key/{print $NF}' apikeyuser1)
export user1secret=$(awk '/secret/{print $NF}' apikeyuser1)
# create ACL for User1 topics
echo "  create ACL for service account"
confluent kafka acl create --allow --service-account $user1id --operation CREATE  --topic $topic1 --prefix  --cluster $source_id
confluent kafka acl create --allow --service-account $user1id --operation WRITE --topic $topic1 --prefix --cluster $source_id
confluent kafka acl create --allow --service-account $user1id --operation READ --topic $topic1 --prefix --cluster $source_id
confluent kafka acl create --allow --service-account $user1id --operation READ --consumer-group $topic1 --prefix --cluster $source_id
echo "END: Topic $topic1"

# second topic
export topic2=project.b1.inventory
echo "Start: create Topic $topic2 in source cluster with ACL and Service data and produce and consume data"
echo "  create topic"
confluent kafka topic create $topic2 --partitions 1 --environment $environment --cluster $source_id
# produce
echo "  produce data"
for i in `seq 1 10`; do echo $i | confluent kafka topic produce $topic2 --environment $environment --cluster $source_id --api-key $sourcekey; done
# consume
echo "  consume data"
confluent kafka topic consume $topic2 --from-beginning --environment $environment --cluster $source_id --api-key $sourcekey
# Create service account
echo "  create service account"
confluent iam service-account create "project.b1.user2" --description "project.b1.user2 can be deleted by Cmutzlitz" -o yaml> user2
export user2id=$(awk '/id:/{print $NF}' user2)
# Create service account key
echo "  create KEY for servive account"
confluent api-key create --resource $source_id --service-account $user2id --description "API Key for Service Account ${user2id} project.b1.user2 " -o yaml > apikeyuser2
export user2key=$(awk '/key/{print $NF}' apikeyuser2)
export user2secret=$(awk '/secret/{print $NF}' apikeyuser2)
# create ACL for User2 topics
echo "  create ACL for service account"
confluent kafka acl create --allow --service-account $user2id --operation CREATE  --topic $topic2 --prefix  --cluster $source_id
confluent kafka acl create --allow --service-account $user2id --operation WRITE --topic $topic2 --prefix --cluster $source_id
confluent kafka acl create --allow --service-account $user2id --operation READ --topic $topic2 --prefix --cluster $source_id
confluent kafka acl create --allow --service-account $user2id --operation READ --consumer-group $topic2 --prefix --cluster $source_id
echo "END: Topic $topic2"

# Check Service accounts
echo "Start: check Service accounts"
for i in `confluent kafka acl list --cluster $source_id -o yaml | awk '/principal: User:/{print $NF}' | cut -d':' -f 2 | awk '!a[$0]++'`
    do
    echo "  Service Account ACL for   ${i} => check it:"
    confluent iam service-account list -o yaml | grep ${i}
    if [[ $(confluent iam  service-account list -o yaml| grep ${i}) ]]; then
        echo "  Service account ${i} still exists, ACL is good"
        confluent kafka acl list --cluster $source_id -o human --service-account  ${i}
    else
        echo "  Service account ${i} does not exist, delete all ACLs belonged to service account ${i}"
        confluent kafka acl list --cluster $source_id -o human --service-account  ${i}
    fi
done
echo "END: check Service accounts"

# Create config_file for destination (rpivate linked) to source cluster (public basic cluster)
echo "create config file for source cluster"
echo "bootstrap.servers=$source_endpoint
security.protocol=SASL_SSL
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=\"${sourcekey}\" password=\"${sourcesecret}\";" > source-link.config
# public DR cluster
echo "create config file for DR cluster"
echo "bootstrap.servers=$destination_endpoint
security.protocol=SASL_SSL
sasl.mechanism=PLAIN
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=\"${destinationkey}\" password=\"${destinationsecret}\";" > destination-link.config

# create config file for cluster link to sync the acls
echo "acl.sync.enable=true
acl.sync.ms=1000
acl.filters={ \"aclFilters\": [ { \"resourceFilter\": { \"resourceType\": \"any\",\"patternType\": \"any\" }, \"accessFilter\": { \"operation\": \"any\", \"permissionType\": \"any\" } } ] }
" > link-configs.properties

# The ojective is now to create link from Destination to source and then create a mirro topic
echo "create cluster link from DR to source"
confluent kafka link create my-link --cluster $destination_id \
    --source-cluster-id $source_id \
    --source-bootstrap-server $source_endpoint \
    --source-api-key $sourcekey --source-api-secret $sourcesecret --config-file link-configs.properties

# Now check all topics, you could filter this later, by project if you want.
echo "#!/bin/bash" > create_mirror_topics_in_destination_cluster.sh
for i in `confluent kafka topic list --environment $environment --cluster $source_id -o yaml | awk '/- name:/{print $NF}' | cut -d':' -f 2 | awk '!a[$0]++'`
do
  echo "Topic is ${i} => mirror topic creation:"
  echo "# Topic is ${i} => mirror topic creation:" >> create_mirror_topics_in_destination_cluster.sh
  echo ">>>>>"
  echo "confluent kafka mirror create ${i} --cluster $destination_id --link my-link"
  echo "confluent kafka mirror create ${i} --cluster $destination_id --link my-link" >> create_mirror_topics_in_destination_cluster.sh
  confluent kafka mirror create ${i} --cluster $destination_id --link my-link
  echo "<<<<<<<"
done

# Produce data to source
echo "produce data to source"
seq 10 15 | confluent kafka topic produce $topic1 --environment $environment --cluster $source_id --api-key $sourcekey
echo "Consume data from destination"
confluent kafka topic consume $topic1 --from-beginning --environment $environment --cluster $destination_id --api-key $destinationkey
# Check if ACL is existng in destination cluster
for i in `confluent kafka acl list --cluster $destination_id -o yaml | awk '/principal: User:/{print $NF}' | cut -d':' -f 2 | awk '!a[$0]++'`
do
  echo "Service Account ACL for   ${i} => check it:"
  confluent iam service-account list -o yaml | grep ${i}
  if [[ $(confluent iam  service-account list -o yaml| grep ${i}) ]]; then
    echo "Service account ${i} still exists, ACL is good"
    confluent kafka acl list --cluster $destination_id -o human --service-account  ${i}
    echo "Create new API Key for destination cluster $destination_id, Key is only linked to source cluster $source_id"
    confluent api-key list --resource $destination_id --service-account ${i}
  else
    echo "Service account ${i} does not exist, delete all ACLs belonged to service account ${i}"
    confluent kafka acl list --cluster $destination_id -o human --service-account  ${i}
fi
done

# Now you have to create a new API Key
echo "Create new API Keys for destination cluster $destination_id service account, Key is only linked to source cluster $source_id"

# End of DR Cluster Setup
echo "<<<<<<<<<<<< End of DR Cluster Setup"





