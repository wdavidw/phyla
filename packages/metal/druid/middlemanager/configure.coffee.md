
# Druid MiddleManager Configure

Example:

```json
{
  "jvm": {
    "xms": "64m",
    "xmx": "64m"
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
      # Miscs
      options.version ?= service.deps.druid.options.version
      options.timezone ?= service.deps.druid.options.timezone
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.hadoop_mapreduce_dir ?= '/usr/hdp/current/hadoop-mapreduce-client'
      options.clean_logs ?= false

## Java

      options.jvm ?= {}
      options.jvm.xms ?= '64m'
      options.jvm.xmx ?= '64m'

## Configuration

      options.runtime ?= {}
      options.runtime['druid.service'] ?= 'druid/middleManager'
      options.runtime['druid.port'] ?= '8091'
      # Number of tasks per middleManager
      options.runtime['druid.worker.capacity'] ?= '3'
      # Task launch parameters
      # Add "-Dhadoop.mapreduce.job.classloader=true" to avoid incompatible jackson versions
      # see https://github.com/druid-io/druid/blob/master/docs/content/operations/other-hadoop.md
      # The "javaOpts" property will be enriched at runtime with the "hdp.version" Java property.
      options.runtime['druid.indexer.runner.javaOpts'] ?= "-server -Xmx2g -Duser.timezone=UTC -Dfile.encoding=UTF-8 -Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager -Dhadoop.mapreduce.job.classloader=true"
      options.runtime['druid.indexer.task.baseTaskDir'] ?= '/var/druid/task'
      # # HTTP server threads
      options.runtime['druid.server.http.numThreads'] ?= '25'
      # Hadoop indexing
      options.runtime['druid.indexer.task.hadoopWorkingPath'] ?= '/tmp/druid-indexing'
      # options.runtime['druid.indexer.task.defaultHadoopCoordinate'] ?= '["org.apache.hadoop:hadoop-client:2.3.0"]'
      options.runtime['druid.indexer.task.defaultHadoopCoordinate'] ?= '["org.apache.hadoop:hadoop-client:2.7.3"]'

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
      # options.runtime['druid.processing.numThreads'] ?= '2'

## Kerberos

      options.krb5_service = merge service.deps.druid.options.krb5_service, options.krb5_service

## Wait

      options.wait_krb5_client = service.deps.krb5_client.options.wait
      options.wait_zookeeper_server = service.deps.zookeeper_server[0].options.wait
      options.wait_hdfs_nn = service.deps.hdfs_nn[0].options.wait
      options.wait_druid_coordinator = service.deps.druid_coordinator[0].options.wait
      options.wait_druid_overlord = service.deps.druid_overlord[0].options.wait
      options.wait = {}
      options.wait.tcp = for srv in service.deps.druid_middlemanager
        host: srv.node.fqdn
        port: srv.options.runtime?['druid.port'] or '8091'

## Dependencies

    {merge} = require 'mixme'
