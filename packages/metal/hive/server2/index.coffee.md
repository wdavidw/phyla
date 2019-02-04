
# Hive Server2

HiveServer2 (HS2) is a server interface that enables remote clients to execute
queries against Hive and retrieve the results. The current implementation, based
on Thrift RPC, is an improved version of HiveServer and supports multi-client
concurrency and authentication. It is designed to provide better support for
open API clients like JDBC and ODBC.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        test_user: module: '@rybajs/metal/commons/test_user', local: true, auto: true, implicit: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server', required: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, required: true
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', required: true
        tez: module: '@rybajs/metal/tez', local: true, auto: true, implicit: true
        hive_metastore: module: '@rybajs/metal/hive/metastore', local: true, auto: true, implicit: true
        hive_hcatalog_local: module: '@rybajs/metal/hive/hcatalog', local: true
        hive_hcatalog: module: '@rybajs/metal/hive/hcatalog', required: true
        hive_server2: module: '@rybajs/metal/hive/server2'
        hive_client: module: '@rybajs/metal/hive/client'
        hbase_thrift: module: '@rybajs/metal/hbase/thrift'
        hbase_client: module: '@rybajs/metal/hbase/client', local: true
        phoenix_client: module: '@rybajs/metal/phoenix/client'
        ranger_admin: module: '@rybajs/metal/ranger/admin', single: true
        log4j: module: '@rybajs/metal/log4j', local: true
      configure:
        '@rybajs/metal/hive/server2/configure'
      commands:
        'install': [
          '@rybajs/metal/hive/server2/install'
          '@rybajs/metal/hive/server2/start'
          '@rybajs/metal/hive/server2/check'
        ]
        'start':
          '@rybajs/metal/hive/server2/start'
        'check':
          '@rybajs/metal/hive/server2/check'
        'status':
          '@rybajs/metal/hive/server2/status'
        'stop':
          '@rybajs/metal/hive/server2/stop'
        'backup':
          '@rybajs/metal/hive/server2/backup'
