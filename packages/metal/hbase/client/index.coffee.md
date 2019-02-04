
# HBase Client

Install the [HBase client](https://hbase.apache.org/apidocs/org/apache/hadoop/hbase/client/package-summary.html) package and configure it with secured access.
you have to use it for administering HBase, create and drop tables, list and alter tables.
Client code accessing a cluster finds the cluster by querying ZooKeeper.

    module.exports =
      deps:
        java: module: 'masson/commons/java', local: true
        test_user: module: '@rybajs/metal/commons/test_user', local: true, auto: true, implicit: true
        mapred_client: module: '@rybajs/metal/hadoop/mapred_client', required: true
        hbase_master: module: '@rybajs/metal/hbase/master', required: true
        hbase_regionserver: module: '@rybajs/metal/hbase/regionserver', required: true
        ranger_admin: module: '@rybajs/metal/ranger/admin', single: true
        ranger_hbase: module: '@rybajs/metal/ranger/plugins/hbase'
      configure:
        '@rybajs/metal/hbase/client/configure'
      commands:
        'install': [
          '@rybajs/metal/hbase/client/install'
          '@rybajs/metal/hbase/client/replication'
          '@rybajs/metal/hbase/client/check'
        ]
        'check':
          '@rybajs/metal/hbase/client/check'
