
# Druid Broker Configure

## Tuning

Druid Brokers also benefit greatly from being tuned to the hardware they run on.
If you are using r3.2xlarge EC2 instances, or similar hardware, the
configuration in the distribution is a reasonable starting point.

If you are using different hardware, we recommend adjusting configurations for
your specific hardware. The most commonly adjusted configurations are:

*   `-Xmx and -Xms`
*   `druid.server.http.numThreads`
*   `druid.cache.sizeInBytes`
*   `druid.processing.buffer.sizeBytes`
*   `druid.processing.numThreads`
*   `druid.query.groupBy.maxIntermediateRows`
*   `druid.query.groupBy.maxResults`

## Example

```json
{
  "jvm": {
    "xms": "24g",
    "xmx": "24g"
  }
}
```

    module.exports = ->
      service = migration.call @, service, 'ryba/druid/broker', ['ryba', 'druid', 'broker'], require('nikita/lib/misc').merge require('.').use,
        krb5_client: key: ['krb5_client']
        java: key: ['java']
        zookeeper_server: key: ['ryba', 'zookeeper']
        druid: key: ['ryba', 'druid', 'base']
        druid_coordinator: key: ['ryba', 'druid', 'coordinator']
        druid_overlord: key: ['ryba', 'druid', 'overlord']
        druid_historical: key: ['ryba', 'druid', 'historical']
        druid_middlemanager: key: ['ryba', 'druid', 'middlemanager']
        druid_broker: key: ['ryba', 'druid', 'broker']
      @config.ryba.druid ?= {}
      options = @config.ryba.druid.broker = service.options

## Identities

      options.group = merge {}, service.use.druid.options.group, options.group
      options.user = merge {}, service.use.druid.options.user, options.user

## Environment

      # Layout
      options.dir = service.use.druid.options.dir
      options.log_dir = service.use.druid.options.log_dir
      options.pid_dir = service.use.druid.options.pid_dir
      # Misc
      options.fqdn = service.node.fqdn
      options.krb5_user ?= service.use.druid.options.krb5_user
      options.version ?= service.use.druid.options.version
      options.timezone ?= service.use.druid.options.timezone
      options.overlord_runtime = service.use.druid_overlord[0].options.runtime
      options.overlord_fqdn = service.use.druid_overlord[0].node.fqdn
      options.iptables ?= service.use.iptables and service.use.iptables.options.action is 'start'
      options.clean_logs ?= false
      options.force_check ?= false

## Java

      options.jvm ?= {}
      options.jvm.xms ?= '24g'
      options.jvm.xmx ?= '24g'
      options.jvm.max_direct_memory_size ?= options.jvm.xmx # Default is 4G

## Kerberos

      options.krb5_service = merge {}, service.use.druid.options.krb5_service, options.krb5_service

## Configuration

Important values:

* druid.processing.numThreads
  The number of processing threads to have available for parallel processing of 
  segments. Our rule of thumb is num_cores - 1, which means that even under 
  heavy load there will still be one core available to do background tasks like 
  talking with ZooKeeper and pulling down segments. If only one core is 
  available, this property defaults to the value 1. Default is "Number of cores - 1 (or 1)".
* druid.broker.http.numConnections: Size of connection pool for the Broker to 
  connect to historical and real-time processes. If there are more queries than 
  this number that all need to speak to the same node, then they will queue up.

      options.runtime ?= {}
      options.runtime['druid.service'] ?= 'druid/broker'
      options.runtime['druid.port'] ?= '8082'
      options.runtime['druid.broker.http.numConnections'] ?= '5'
      options.runtime['druid.broker.cache.useCache'] ?= 'true'
      options.runtime['druid.broker.cache.populateCache'] ?= 'true'
      options.runtime['druid.server.http.numThreads'] ?= '25'
      options.runtime['druid.cache.type'] ?= 'local'
      options.runtime['druid.cache.sizeInBytes'] ?= '2000000000'

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

      # options.runtime['druid.processing.buffer.sizeBytes'] ?= '1073741824'
      # options.runtime['druid.processing.numThreads'] ?= '1'
      # TODO, if buffer.sizeBytes and numThreads are provided, assert they fit within the xmx value

## Wait

      options.wait_zookeeper_server = service.use.zookeeper_server[0].options.wait
      options.wait_druid_coordinator = service.use.druid_coordinator[0].options.wait
      options.wait_druid_overlord = service.use.druid_overlord[0].options.wait
      options.wait_druid_historical = service.use.druid_historical[0].options.wait
      options.wait_druid_middlemanager = service.use.druid_middlemanager[0].options.wait
      options.wait = {}
      options.wait.tcp = for srv in service.use.druid_broker
        host: srv.node.fqdn
        port: srv.options.runtime?['druid.port'] or '8082'

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'
