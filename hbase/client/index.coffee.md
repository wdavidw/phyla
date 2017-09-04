
# HBase Client

Install the [HBase client](https://hbase.apache.org/apidocs/org/apache/hadoop/hbase/client/package-summary.html) package and configure it with secured access.
you have to use it for administering HBase, create and drop tables, list and alter tables.
Client code accessing a cluster finds the cluster by querying ZooKeeper.

    module.exports =
      use:
        java: module: 'masson/commons/java', local: true
        mapred_client: module: 'ryba/hadoop/mapred_client', required: true
        hbase_master: module: 'ryba/hbase/master', required: true
        hbase_regionserver: module: 'ryba/hbase/regionserver', required: true
      configure:
        'ryba/hbase/client/configure'
      commands:
        'install': ->
          options = @config.ryba.hbase.client
          @call 'ryba/hbase/client/install', options
          @call 'ryba/hbase/client/replication', options
          @call 'ryba/hbase/client/check', options
        'check': ->
          options = @config.ryba.hbase.client
          @call 'ryba/hbase/client/check', options
