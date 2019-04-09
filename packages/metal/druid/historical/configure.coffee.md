
# Druid Historical Configure

## Tuning

Druid Historicals and MiddleManagers serve queries and can be co-located on the
same hardware. Both Druid processes benefit greatly from being tuned to the
hardware they run on. If you are running Tranquility Server or Kafka, you can
also colocate Tranquility with these two Druid processes. If you are using
r3.2xlarge EC2 instances, or similar hardware, the configuration in the
distribution is a reasonable starting point.

If you are using different hardware, we recommend adjusting configurations for
your specific hardware. The most commonly adjusted configurations are:

*   `-Xmx and -Xms`
*   `druid.server.http.numThreads`
*   `druid.processing.buffer.sizeBytes`
*   `druid.processing.numThreads`
*   `druid.query.groupBy.maxIntermediateRows`
*   `druid.query.groupBy.maxResults`
*   `druid.server.maxSize and druid.segmentCache.locations on Historical Nodes`
*   `druid.worker.capacity on MiddleManagers`

## Example

```json
{
  "jvm": {
    "xms": "8g",
    "xmx": "8g"
  }
}
```

    module.exports = (service) ->
      options = service.options

## Identity
      
      options.group ?= merge service.deps.druid.options.user, options.group
      options.user ?= merge service.deps.druid.options.user, options.user

## Environment

      # Layout
      options.dir = service.deps.druid.options.dir
      options.log_dir = service.deps.druid.options.log_dir
      options.pid_dir = service.deps.druid.options.pid_dir
      options.hadoop_conf_dir = service.deps.hdfs_client.options.conf_dir
      # Miscs
      options.version ?= service.deps.druid.options.version
      options.timezone ?= service.deps.druid.options.timezone
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.clean_logs ?= false

## Java

      options.jvm ?= {}
      options.jvm.xms ?= '8g'
      options.jvm.xmx ?= '8g'
      options.jvm.max_direct_memory_size ?= options.jvm.xmx # Default is 4G

## Configuration

      options.runtime ?= {}
      options.runtime['druid.service'] ?= 'druid/historical'
      options.runtime['druid.port'] ?= '8083'
      options.runtime['druid.server.http.numThreads'] ?= '25'
      options.runtime['druid.segmentCache.locations'] ?= '[{"path":"var/druid/segment-cache","maxSize"\:130000000000}]'
      options.runtime['druid.server.maxSize'] ?= '130000000000'

### Processing

The broker uses processing configs for nested groupBy queries. And, optionally, 
Long-interval queries (of any type) can be broken into shorter interval queries 
and processed in parallel inside this thread pool. For more details, see "chunkPeriod" 
in Query Context doc.

* druid.processing.buffer.sizeBytes
  This specifies a buffer size for the storage of intermediate results. The 
  computation engine in both the Historical and Realtime nodes will use a 
  scratch buffer of this size to do all of their intermediate computations 
  off-heap. Larger values allow for more aggregations in a single pass over 
  the data while smaller values can require more passes depending on the query 
  that is being executed. Default is "1073741824 (1GB)".
* druid.processing.numMergeBuffers: The number of direct memory buffers 
  available for merging query results. The buffers are sized by 
  druid.processing.buffer.sizeBytes. This property is effectively a concurrency 
  limit for queries that require merging buffers. If you are using any queries 
  that require merge buffers (currently, just groupBy v2) then you should have 
  at least two of these. Default is "max(2, druid.processing.numThreads / 4)".

```
maxDirectMemory > memoryNeeded
memoryNeeded = druid.processing.buffer.sizeBytes * (druid.processing.numMergeBuffers + druid.processing.numThreads + 1)
```
      # options.runtime['druid.processing.buffer.sizeBytes'] ?= '536870912'
      # options.runtime['druid.processing.numThreads'] ?= '7'
      # TODO, if buffer.sizeBytes and numThreads are provided, assert they fit within the xmx value

## Kerberos

      options.krb5_service = merge service.deps.druid.options.krb5_service, options.krb5_service

## Wait

      options.wait_krb5_client ?= service.deps.krb5_client.options.wait
      options.wait_zookeeper_server ?= service.deps.zookeeper_server[0].options.wait
      options.wait_hdfs_nn ?= service.deps.hdfs_nn[0].options.wait
      options.wait_druid_coordinator ?= service.deps.druid_coordinator[0].options.wait
      options.wait_druid_overlord ?= service.deps.druid_overlord[0].options.wait
      options.wait = {}
      options.wait.tcp = for srv in service.deps.druid_historical
        host: srv.node.fqdn
        port: srv.options.runtime?['druid.port'] or '8083'


## Dependencies

    {merge} = require 'mixme'
