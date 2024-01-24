# HA Information/Requirement (HAir) check

Content
* Quota Management
* Schema Validation Demo - protect your consumers
* Schema Linking
* Backup and Recovery with S3 connector
* Backup and Recovery with Confluent Replicator - active-passive cluster
* Build a DR cluster - Source is Basic Cluster and DR cluster is a dedicated Cluster

## Quota Management
Every cloud services has limits implemented. The limits around Confluent cloud are visile via cli and API. Documented are limits [here](https://docs.confluent.io/cloud/current/clusters/cluster-types.html). 
Confluent filters between scope like organization, user-accounts etc.
To get current limits of the Confluent Cloud Org execite cli command:
```bash
confluent login
confluent service-quota list  organization
# output
#  iam.max_audit_log_api_keys.per_org | Max Audit Log API Keys Per     | organization |         10000 | 9759ca38-aad4-414e-9c2c-01e598568df6 |             
```
The same can be done with API calls:
```bash
# Quota per Organization
curl --request GET \
  --url 'https://api.confluent.cloud/service-quota/v1/applied-quotas?scope=ORGANIZATION&page_size=100' \
  --header 'Authorization: Basic APIKEY-SECRETCODE'
```
A typical use case of dealing with limits could be the amount of Keys a user can create. It could happen that you get error that limit is exceeded. Then you can check your current setting:
```bash
curl --request GET \
 --url 'https://api.confluent.cloud/service-quota/v1/applied-quotas?scope=USER_ACCOUNT&page_size=100' \
 --header 'Authorization: Basicbase64ERGEBNIS_from_ECHO'
# output
# {
# "api_version": "service-quota/v1",
# "data": [
#   {
#     "api_version": "service-quota/v1",
#     "applied_limit": 100,
#     "default_limit": 10,
#     "display_name": "Max Kafka API Keys Per User",
#     "id": "iam.max_cloud_api_keys.per_user",
#     "kind": "AppliedQuota",
# ...
```
As you can see the default valiie is 10 keys per user. In that case it was increased to 100 keys per user. 
If the limit is too small than you can create a support ticket under support.confluent.io and ask for increase limits.

## Schema Validation Demo - protect your consumers
Enable prereqs on your broker `$CONFLUENT_HOME/etc/kafka/server.properties`and set Schema Registry URL `confluent.schema.registry.url=http://localhost:8081`
I prepared a simple Demo to show what is happening if your produce a wrong formated event into Kafka without SR validation and with SR validation.

Pre-req:
* running MacOS
* installed confluent local cluster
* installed iTerm2

### Start
Run demo and follow the instruction prompts in Demo:
```bash
cd schema-registry-demo/
./01_startSRValidation.sh
```

### Stop
Stop the demo by cleaning the cluster.
```bash
cd schema-registry-demo/
./02_stopSRValidation.sh
``` 

## Schema Linking
Schema Linking in combination with cluster linking could be seen as DR solution for Schema Registry. It keeps schemas in sync across tow schema registries. Please follow the [documentation](https://docs.confluent.io/cloud/current/sr/schema-linking.html).

run demo to show schema linking.
### Start
Run demo and follow the instruction prompts in Demo:
```bash
cd schema-registry-demo/
./01_startSRLinking.sh
```
## Backup and Recovery with S3 connector
I use the [Confluent Cloud setup guide](https://github.com/hendrasutanto/confluent-cloud-setup-guide) for this demo
```bash
# Follow the guide in the link above, in my case it installed under my Demos directory
cd ~/Demos/examples/cp-quickstart
# Start ccloud cluster
./start-cloud.sh
```
A cluster should be provisioned you should check wit ccloud UI.

### configure S3 Connector
follow the [demo guide](https://github.com/hendrasutanto/confluent-cloud-setup-guide#step-2---setup-s3-sink-connector)
You need to have AWS credentails with correct privileges:
* create a bucket in AWS in my case: cmutzlitz-us-west-2 in us-west-2
* Create connector in console with values from here: https://github.com/hendrasutanto/confluent-cloud-setup-guide#step-2---setup-s3-sink-connector
* Get API Keys from creation cluster script `cat stack-configs/java-service-account-sa-38102w.config`. you need to have look on username and password
The connector json file could lokk like this:
```bash
{
  "name": "S3_SINKCMUETZLITZ_0",
  "config": {
    "topics": "pksqlc-gw3x1ACCOMPLISHED_FEMALE_READERS",
    "input.data.format": "JSON_SR",
    "connector.class": "S3_SINK",
    "name": "S3_SINKConnector_0",
    "kafka.auth.mode": "KAFKA_API_KEY",
    "kafka.api.key": "KEY",
    "kafka.api.secret": "SECRET",
    "aws.access.key.id": "AWAKEY",
    "aws.secret.access.key": "AWSSECRET",
    "s3.bucket.name": "cmutzlitz-us-west-2",
    "output.data.format": "AVRO",
    "time.interval": "HOURLY",
    "flush.size": "1000",
    "tasks.max": "1"
  }
}
```
run  via connector API - create own Cloud API Key:
```bash
confluent login
confluent api-key create --resource cloud --description "API Key Cmutzlitz for Connect API"
echo -n "KEY:SECRET" | base64
# check connector running
curl --request GET \
  --url 'https://api.confluent.cloud/connect/v1/environments/env-x29ox/clusters/lkc-81znq5/connectors' \
  --header 'Authorization: Basic BASECODESTRING-From-echo' | jq
# create Connector
# before creating connector which access we get
confluent api-key list | grep KEY
confluent iam service-account list | grep sa-38102w
confluent iam rbac role-binding list --principal User:sa-38102w
confluent kafka acl list | grep sa-38102w
curl --request POST 'https://api.confluent.cloud/connect/v1/environments/env-x29ox/clusters/lkc-81znq5/connectors' \
--header 'authorization: Basic BASECODESTRING-From-echo' \
--header 'Content-Type: application/json' \
--data "@s3_connector.json" | jq
```
Check if S3 is running, wait in ccloud and check S3 if data running into bucket.
Data which was sinked with S3 connector could sources with S3 source into a topic. So backup and recovery of data is given.

## Backup and Recovery with Confluent Replicator
copy the content of a topic into second cluster. Pre-req is having Confluent Platform installed on your Mac. In my case I run CP 7.0
### Pre-Configure
the shell script `env-vars` has some variables which need to fit to your Confluent Cloud environment
* Your Confluent Cloud Environment:  XX_CCLOUD_ENV=XXXXXX
* Your Confluent Cloud Login: XX_CCLOUD_EMAIL=YYYYYYY
* Your Confluent Cloud Password: XX_CCLOUD_PASSWORD=ZZZZZZZZZ
* The name for the Confluent Cluster: $XX_CCLOUD_CLUSTERNAME1 and $XX_CCLOUD_CLUSTERNAME2

## Start the demo showcase
Start the demo
```bash
cd replicator-demo/
source env-vars
./00_create_ccloudcluster.sh
```
iterm Terminals with producer and consumer start automatically. Replcator is started, if you now produce into source cluster the content will be replicated into target cluster:

## Drop Topic in Source Cluster
Typically customers want to protect yourself for human errors. So, the big question, how can you protect your environment for deleting topics?
Let's try to play this use case in our replicator use case demo.
Drop the topic in source cluster and see if the topic will be dropped as well in destination cluster.
* topic.poll.interval.ms: How often to poll for new topics matching whitelist or regex. (default 120000)
* topic.auto.create: whether to auto create topics in destination cluster
* topic.config.sync: whether to periodically sync topic configuration to destination cluster (defaults to true)
```bash
kafka-topics --bootstrap-server $(cat ccloud_user1.properties | grep "bootstrap.servers" | cut -d'=' -f2) --command-config ccloud_user1.properties --delete --topic cmorders_avro
# check topic in source
kafka-topics --bootstrap-server $(cat ccloud_user1.properties | grep "bootstrap.servers" | cut -d'=' -f2) --command-config ccloud_user1.properties --list
# check topic in target
kafka-topics --bootstrap-server $(cat ccloud_user2.properties | grep "bootstrap.servers" | cut -d'=' -f2) --command-config ccloud_user2.properties --list
```
Source Topic cmorders_avro was dropped and should not visible anymore. Target topic cmorders_avro is still there. You could restore topic including content to replicate back into source  cluster, this is not covered here.
## Stop the demo showcase
To delete the complete environment:
```bash
cd replicator-demo/
./02_drop_ccloudcluster.sh
```

## Build a DR cluster - Source is Basic Cluster and DR cluster is a dedicated Cluster
This demo will create an
* environment with
* 2 clusters: 1 Basic as source cluster with two topics, service accounts and ACL policy and a one dedicated cluster as DR cluster
![DR cliuster setup](dr-cluster-demo/img/clustersetup.png)

Via cluster linking we will mirror topics including ACLs from source to dr cluster.

### START
```bash
cd dr-cluster-demo/
./00_setup_ccloud_dr_cluster.sh
```
The `00_setup_ccloud_dr_cluster.sh` will create an DR environment. In failover case and need to do the failover manuelly.
Please follow the documentation or follow this [script](dr-cluster-demo/manual_failover.md).

### Delete topic in source cluster
Does this DR feature also protect for human errors, like deleting a topic, let's try.
```bash
confluent kafka topic delete $topic1 --cluster $source_id --environment $environment
# Deleted topic "project.a1.orders".
# Shold be able to consume from DR
confluent kafka topic consume $topic1 --from-beginning --environment env-w7z1qj --cluster $destination_id --api-key $destinationkey
```
The cluster link should still exists and the mirror topic in DR cluster as well. The mirror topic is still read only.
![clusterlink](img/mirror_topic_in_dr.png)
Now you have copy of your deleted topic. You can restore the topic e.g. with [kcat](https://rmoff.net/2019/09/29/copying-data-between-kafka-clusters-with-kafkacat/). This is not covered here. 
After a while you will get the information that mirroring failed.
But you still consume from mirror topic `confluent kafka topic consume $topic1 --from-beginning --environment env-w7z1qj --cluster $destination_id --api-key $destinationkey` till retention policy.
![cluster link mirroring failed](img/mirroring_failed.png)

### Clean demo environment
```bash
cd dr-cluster-demo/
./01_delete_ccloud_dr_cluster.sh
```
## Connect Cluster with Confluent Cloud
This sample is not HA in general. It show more or less, how easy it is to run a self-managed connect cluster in k8s connecting against Confluent cloud.
Most of our customers running a combination of self-managed connect cluster and fully managed connectors in Confluent Cloud. Reasons are very different:
 * Network limits
 * Connector is not fully-managed
 * Connector need a special setup which can not addressed in Confluent Cloud.
 * any others
A best practice deployment would look like the next diagram.
![Self-Managed Cluster with K8s](img/connect_cluster_with_cfk.png)
The k8s infrastruce could be everything like AKS, EKS, GKE, openshift, vanilla k8s etc.

The deployment is very easy with Confluent for Kubernetes (CFK). With a running Confluent Cloud UBB contract you will get an enterprise license and are allowed to run CFK.
Please follow my runbook for provision a connect cluster with datagen connector producing into Confluent Cloud.
```bash
cd self-managed_connect_cluster/
# start docker
### start minicube
minikube start --kubernetes-version=v1.22.2
minikube status

### Install CFK
# Create namespace to use
kubectl create ns confluent
# Set namespace for current context to `confluent`. With this in place, all subsequent kubectl commands will assume that the namespace to use is `confluent`
kubectl config set-context --current --namespace confluent
kubectl get namespace
# Check your kubectl context
kubectl config get-contexts

# Add the Confluent Helm repository. Helm is used to package the Confluent for Kubernetes(CFK) Operator and CRDs.
helm repo add confluentinc https://packages.confluent.io/helm
# Install CFK Operator
helm install cfk-operator confluentinc/confluent-for-kubernetes -n confluent

# Once install is successful, you'll see the installed chart
helm list -n confluent
# Output should look like this
# NAME          NAMESPACE  REVISION  STATUS    CHART                              APP VERSION
# cfk-operator  confluent  1         updated     confluent-for-kubernetes-0.174  2.0.2

# The Helm chart deploys the Confluent for Kubernetes  (CFK) Operator as a pod. You should see it up and running.
kubectl get pods -n confluent
# Output should look like this
# NAME                                  READY   STATUS    RESTARTS   AGE
# confluent-operator-66bcf88444-vd5gg   1/1     Running   0          14h

# get CFK examples see https://github.com/confluentinc/confluent-kubernetes-examples/tree/master/hybrid/ccloud-connect-confluent-hub
wget https://github.com/confluentinc/confluent-kubernetes-examples/archive/refs/heads/master.zip
unzip master.zip 
cd confluent-kubernetes-examples-master/hybrid/ccloud-connect-confluent-hub/
export TUTORIAL_HOME=./self-managed_connect_cluster//confluent-kubernetes-examples-master/hybrid/ccloud-connect-confluent-hub

# Add credentials into txt fields, before that change it to your setup, you can the samples in github-repo
kubectl create secret generic ccloud-credentials --from-file=plain.txt=ccloud-credentials.txt
kubectl create secret generic ccloud-sr-credentials --from-file=basic.txt=ccloud-sr-credentials.txt
## API key from my cluster 
cat ccloud-credentials.txt
kubectl get secret ccloud-credentials
## SR API KEy
cat ccloud-sr-credentials.txt
kubectl get secret ccloud-sr-credentials
# Add everything into yml, show the on-demand part in connect, change this yaml to your setup (Bootstrap-Server, SR-URL, Connectors)
cat kafka-connect.yaml

# Provision Connect cluster
kubectl apply -f $TUTORIAL_HOME/kafka-connect.yaml
kubectl get pods -n confluent
#### WAIT a WHILE 5 min
# open Port to CONNECT RESTA API
kubectl port-forward connect-0 8083
# get connectors
curl http://localhost:8083/connectors/
curl http://localhost:8083/connector-plugins/ | jq

# Open a different terminal and start the connector
# Create Datagen Connector
curl -X PUT \
-H "Content-Type: application/json" \
--data '{
	"name": "datagen-users",
	"connector.class": "io.confluent.kafka.connect.datagen.DatagenConnector",
	"tasks.max": "1",
	"kafka.topic": "users",
	"quickstart": "USERS",
	"key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.json.JsonConverter",
    "value.converter.schemas.enable": "false",
    "max.interval": "100",
    "iterations": "10000000"
}' \
http://localhost:8083/connectors/datagen-users/config | jq .

# check status
curl -X GET http://localhost:8083/connectors/datagen-users | jq
curl -X GET http://localhost:8083/connectors/datagen-users/status | jq

#Check in ccloud UI in topic viewer under topic users

# delete connector
curl -X DELETE http://localhost:8083/connectors/datagen-users/ | jq
# Delete connect cluster
kubectl delete -f $TUTORIAL_HOME/kafka-connect.yaml
kubectl get pods -n confluent
minikube stop
```
The HA part need to be configured. Add additional workers (replica) etc.
