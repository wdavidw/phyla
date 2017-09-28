
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

    module.exports = ->
      service = migration.call @, service, 'ryba/druid/middlemanager', ['ryba', 'druid', 'middlemanager'], require('nikita/lib/misc').merge require('.').use,
        krb5_client: key: ['krb5_client']
        java: key: ['java']
        zookeeper_server: key: ['ryba', 'zookeeper']
        hdfs_nn: key: ['ryba', 'hdfs', 'nn']
        mapred_client: key: ['ryba', 'mapred']
        druid: key: ['ryba', 'druid', 'base']
        druid_coordinator: key: ['ryba', 'druid', 'coordinator']
        druid_overlord: key: ['ryba', 'druid', 'overlord']
        # druid_historical: key: ['ryba', 'druid', 'historical']
        druid_middlemanager: key: ['ryba', 'druid', 'middlemanager']
        # druid_broker: key: ['ryba', 'druid', 'broker']
      @config.ryba.druid ?= {}
      options = @config.ryba.druid.middlemanager = service.options

## Identity
      
      options.group ?= merge {}, service.use.druid.options.user, options.group
      options.user ?= merge {}, service.use.druid.options.user, options.user

## Environnment

      # Layout
      options.dir = service.use.druid.options.dir
      options.log_dir = service.use.druid.options.log_dir
      options.pid_dir = service.use.druid.options.pid_dir
      # Miscs
      options.version ?= service.use.druid.options.version
      options.timezone ?= service.use.druid.options.timezone
      options.iptables ?= service.use.iptables and service.use.iptables.options.action is 'start'
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

      options.krb5_service = merge {}, service.use.druid.options.krb5_service, options.krb5_service

## Wait

      options.wait_krb5_client = service.use.krb5_client.options.wait
      options.wait_zookeeper_server = service.use.zookeeper_server[0].options.wait
      options.wait_hdfs_nn = service.use.hdfs_nn[0].options.wait
      options.wait_druid_coordinator = service.use.druid_coordinator[0].options.wait
      options.wait_druid_overlord = service.use.druid_overlord[0].options.wait
      options.wait = {}
      options.wait.tcp = for srv in service.use.druid_middlemanager
        host: srv.node.fqdn
        port: srv.options.runtime?['druid.port'] or '8091'

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'
