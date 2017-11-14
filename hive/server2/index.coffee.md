
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
        test_user: module: 'ryba/commons/test_user', local: true, auto: true, implicit: true
        zookeeper_server: module: 'ryba/zookeeper/server', required: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, required: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', required: true
        tez: module: 'ryba/tez', local: true, auto: true, implicit: true
        hive_metastore: module: 'ryba/hive/metastore', local: true, auto: true, implicit: true
        hive_hcatalog_local: module: 'ryba/hive/hcatalog', local: true
        hive_hcatalog: module: 'ryba/hive/hcatalog', required: true
        hive_server2: module: 'ryba/hive/server2'
        hive_client: module: 'ryba/hive/client'
        hbase_thrift: module: 'ryba/hbase/thrift'
        hbase_client: module: 'ryba/hbase/client', local: true
        phoenix_client: module: 'ryba/phoenix/client'
        ranger_admin: module: 'ryba/ranger/admin', single: true
        log4j: module: 'ryba/log4j', local: true
      configure:
        'ryba/hive/server2/configure'
      commands:
        'install': [
          'ryba/hive/server2/install'
          'ryba/hive/server2/start'
          'ryba/hive/server2/check'
        ]
        'start':
          'ryba/hive/server2/start'
        'check':
          'ryba/hive/server2/check'
        'status':
          'ryba/hive/server2/status'
        'stop':
          'ryba/hive/server2/stop'
        'backup':
          'ryba/hive/server2/backup'
