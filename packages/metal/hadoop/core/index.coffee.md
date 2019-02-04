
# Hadoop Core

## Encryption

Setting hadoop.rpc.protection to privacy encrypts all communication from clients
to Namenode, from clients to Resource Manager, from datanodes to Namenodes, from
Node Managers to Resource managers, and so on.

Setting dfs.data.transfer.protection to privacy encrypts all data transfer
between clients and Datanodes. The clients could be any HDFS client like a
map-task reading data, reduce-task writing data or a client JVM reading/writing
data.

Setting dfs.http.policy and yarn.http.policy to HTTPS_ONLY causes all HTTP
traffic to be encrypted. This includes the web UI for Namenodes and Resource
Managers, Web HDFS interactions, and others.

    module.exports =
      deps:
        ssl: module: 'masson/core/ssl', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        test_user: module: '@rybajs/metal/commons/test_user', local: true, auto: true, implicit: true
        hdp: module: '@rybajs/metal/hdp', local: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
        ganglia: module: '@rybajs/metal/retired/ganglia/collector', single: true
        graphite: module: '@rybajs/metal/graphite', single: true
        metrics: module: '@rybajs/metal/metrics', local: true
        log4j: module: '@rybajs/metal/log4j', local: true
        hadoop_core: module: '@rybajs/metal/hadoop/core'
      configure:
        '@rybajs/metal/hadoop/core/configure'
      commands:
        'install':
          '@rybajs/metal/hadoop/core/install'
