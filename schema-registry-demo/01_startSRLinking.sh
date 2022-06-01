#!/bin/bash

export uuid=$(uuidgen)
export sourceenv=source-$uuid
export destinationenv=destination-$uuid
# create cluster source and env
confluent login
# Environments
echo "confluent environment create $sourceenv"
confluent environment create $sourceenv -o yaml > sourcenv
echo "confluent environment create $destinationenv"
confluent environment create $destinationenv -o yaml > destinationenv
export SOURCEENVID=$(awk '/id:/{print $NF}' sourcenv)
export DESTINATIONENVID=$(awk '/id:/{print $NF}' destinationenv)
# Clusters
confluent kafka cluster create $sourceenv --cloud 'gcp' --region 'europe-west1' --type basic --environment $SOURCEENVID -o yaml > clusterid1
confluent kafka cluster create $destinationenv --cloud 'aws' --region 'eu-central-1' --type basic --environment $DESTINATIONENVID -o yaml > clusterid2
echo "clusters created wait 30 sec"
sleep 30
# set cluster id as parameter
export CCLOUD_CLUSTERID1=$(awk '/id:/{print $NF}' clusterid1)
export CCLOUD_CLUSTERID1_BOOTSTRAP=$(awk '/endpoint: SASL_SSL:\/\//{print $NF}' clusterid1 | sed 's/SASL_SSL:\/\///g')
export CCLOUD_CLUSTERID2=$(awk '/id:/{print $NF}' clusterid2)
export CCLOUD_CLUSTERID2_BOOTSTRAP=$(awk '/endpoint: SASL_SSL:\/\//{print $NF}' clusterid2 | sed 's/SASL_SSL:\/\///g')
# Enable Schema Registry
confluent schema-registry cluster enable --cloud gcp --geo 'eu' --environment $SOURCEENVID -o yaml > srsource
confluent schema-registry cluster enable --cloud aws --geo 'eu' --environment $DESTINATIONENVID -o yaml > srdestination
Echo "Schema registries enabled wait 30 sec..."
sleep 30
export SRCLUSTERID1=$(awk '/id:/{print $NF}' srsource)
export SRCLUSTERID1_URL=$(awk '/endpoint_url:/{print $NF}' srsource )
export SRCLUSTERID2=$(awk '/id:/{print $NF}' srdestination)
export SRCLUSTERID2_URL=$(awk '/endpoint_url:/{print $NF}' srdestination )
# Keys for SR
confluent api-key create --resource $SRCLUSTERID1 --description " Key for $SRCLUSTERID1" --environment $SOURCEENVID -o yaml > srid1_key
export SRID1KEY=$(awk '/key:/{print $NF}' srid1_key)
export SRID1SECRET=$(awk '/secret:/{print $NF}' srid1_key )
confluent api-key create --resource $SRCLUSTERID2 --description " Key for $SRCLUSTERID2" --environment $DESTINATIONENVID -o yaml > srid2_key
export SRID2KEY=$(awk '/key:/{print $NF}' srid2_key)
export SRID2SECRET=$(awk '/secret:/{print $NF}' srid2_key )
echo "Source Key"
cat srid1_key
echo "Destination  Key"
cat srid2_key
echo "API keys for SRs are created wait 30 sec..."
sleep 30
# Create source subjects
echo "create subject in source environment SR"
confluent schema-registry schema create --subject ":.source:schema" --schema schema.avro --type AVRO --api-key $SRID1KEY --api-secret $SRID1SECRET --environment $SOURCEENVID  -o yaml 
# exporter config
echo "schema.registry.url=$SRCLUSTERID2_URL
basic.auth.credentials.source=USER_INFO
basic.auth.user.info=$SRID2KEY:$SRID2SECRET" > config.txt
# create the exporter for source-destination
echo "create exporter from source to destination SR"
confluent schema-registry exporter create source-destination-exporter --subjects ":*:" --config-file ./config.txt --environment $SOURCEENVID --api-key $SRID1KEY --api-secret $SRID1SECRET  -o yaml
confluent schema-registry exporter describe source-destination-exporter --environment $SOURCEENVID --api-key $SRID1KEY --api-secret $SRID1SECRET  -o yaml
# List exported Schemata in desition SR
echo "list subject in Destination SR"
confluent schema-registry subject list --prefix ":*:" --environment $DESTINATIONENVID --api-key $SRID2KEY --api-secret $SRID2SECRET  -o yaml
echo "Delete everything by press ENTER:"
read
echo "Delete the complete environment"
#export SCHEMADESTINATION=":.$SRCLUSTERID1.source:schema"
#echo "delete exporter"
#confluent schema-registry exporter delete source-destination-exporter --environment $SOURCEENVID --api-key $SRID1KEY --api-secret $SRID1SECRET  
#echo "delete subjects"
#confluent schema-registry schema delete --subject ${SCHEMADESTINATION} --version latest  --environment $DESTINATIONENVID --api-key $SRID2KEY --api-secret $SRID2SECRET 
#confluent schema-registry schema delete --subject ":.source:schema" --version latest --environment $SOURCEENVID --api-key $SRID1KEY --api-secret $SRID1SECRET  
# delete keys
#echo "delete keys"
#confluent api-key delete $SRID1KEY
#confluent api-key delete $SRID2KEY
# delete clusters
#echo "delete kafka clusters"
#confluent kafka cluster delete $CCLOUD_CLUSTERID1 --environment $SOURCEENVID
#confluent kafka cluster delete $CCLOUD_CLUSTERID2 --environment $DESTINATIONENVID
# delete environments
echo "delete environments"
confluent environment delete $SOURCEENVID
confluent environment delete $DESTINATIONENVID
rm clusterid1
rm clusterid2
rm config.txt
rm destinationenv
rm sourcenv
rm srdestination
rm srid1_key
rm srid2_key
rm srsource
echo "Demo finished, environment deleted"
