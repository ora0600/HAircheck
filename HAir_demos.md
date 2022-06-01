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

### Clean demo environment
```bash
cd dr-cluster-demo/
./01_delete_ccloud_dr_cluster.sh
```
