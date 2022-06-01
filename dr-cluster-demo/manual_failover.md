
For a manual failover, please follow these steps
```bash
# Create new API Key for Service accounts on DRCluster ${user1} and ${user2}
confluent api-key create --resource lkc-nzg2v --service-account sa-do0vqy
+---------+------------------------------------------------------------------+
| API Key | XXX                                                              |
| Secret  | YYYYYYYYY                                                        |
+---------+------------------------------------------------------------------+

# Do the failover
# dry run
confluent kafka mirror failover project.a1.orders --link dr-link --cluster lkc-nzg2v --dry-run
Mirror Topic Name | Partition | Partition Mirror Lag | Error Message | Error Code | Last Source Fetch Offset  
--------------------+-----------+----------------------+---------------+------------+---------------------------
  project.a1.orders |         0 |                    0 |               |            |                       17  
# stop mirring
confluent kafka mirror failover project.a1.orders --link dr-link --cluster lkc-nzg2v
confluent kafka mirror list --cluster lkc-nzg2v
  Link Name | Mirror Topic Name | Num Partition | Max Per Partition Mirror Lag | Source Topic Name | Mirror Status | Status Time Ms  
------------+-------------------+---------------+------------------------------+-------------------+---------------+-----------------
  dr-link   | project.a1.orders |             1 |                            0 | project.a1.orders | STOPPED       |  1639037597867
# now read-only is done, and we could produce
seq 21 25 | confluent kafka topic produce project.a1.orders --cluster drclusertid --api-key KEY --api-secret SECRET
confluent kafka topic consume -b project.a1.orders --group project.a1.orders --cluster drclusertid --api-key KEY --api-secret SECRET
# Once we changed and do failover we cannot come back.
```

Please follow the offical [documentation](https://docs.confluent.io/cloud/current/multi-cloud/cluster-linking/dr-failover.html#simulate-a-failover-to-the-dr-cluster) for a detailed description.