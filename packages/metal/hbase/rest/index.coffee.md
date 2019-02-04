
# HBase Rest Gateway
Stargate is the name of the REST server bundled with HBase.
The [REST Server](http://wiki.apache.org/hadoop/Hbase/Stargate) is a daemon which enables other application to request HBASE database via http.
Of course we deploy the secured version of the configuration of this API.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        test_user: module: '@rybajs/metal/commons/test_user', local: true, auto: true, implicit: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        hdfs_dn: module: '@rybajs/metal/hadoop/core', required: true
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', local: true, required: true
        hbase_master: module: '@rybajs/metal/hbase/master', required: true
        hbase_regionserver: module: '@rybajs/metal/hbase/regionserver', required: true
        hbase_client: module: '@rybajs/metal/hbase/client', local: true
        hbase_rest: module: '@rybajs/metal/hbase/thrift'
        ranger_admin: module: '@rybajs/metal/ranger/admin', single: true
        ranger_hbase: module: '@rybajs/metal/ranger/plugins/hbase'
      configure:
        '@rybajs/metal/hbase/rest/configure'
      commands:
        'check':
          '@rybajs/metal/hbase/rest/check'
        'install': [
          '@rybajs/metal/hbase/rest/install'
          '@rybajs/metal/hbase/rest/start'
          '@rybajs/metal/hbase/rest/check'
        ]
        'start':
          '@rybajs/metal/hbase/rest/start'
        'status':
          '@rybajs/metal/hbase/rest/status'
        'stop':
          '@rybajs/metal/hbase/rest/stop'
