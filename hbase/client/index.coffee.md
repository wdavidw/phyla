
# HBase Client

Install the [HBase client](https://hbase.apache.org/apidocs/org/apache/hadoop/hbase/client/package-summary.html) package and configure it with secured access.
you have to use it for administering HBase, create and drop tables, list and alter tables.
Client code accessing a cluster finds the cluster by querying ZooKeeper.

    module.exports =
      deps:
        java: module: 'masson/commons/java', local: true
        test_user: module: 'ryba/commons/test_user', local: true, auto: true, implicit: true
        mapred_client: module: 'ryba/hadoop/mapred_client', required: true
        hbase_master: module: 'ryba/hbase/master', required: true
        hbase_regionserver: module: 'ryba/hbase/regionserver', required: true
        ranger_admin: module: 'ryba/ranger/admin', single: true
        ranger_hbase: module: 'ryba/ranger/plugins/hbase'
      configure:
        'ryba/hbase/client/configure'
      commands:
        'install': [
          'ryba/hbase/client/install'
          'ryba/hbase/client/replication'
          'ryba/hbase/client/check'
        ]
        'check':
          'ryba/hbase/client/check'
