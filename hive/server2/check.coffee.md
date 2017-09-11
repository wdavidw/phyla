
# Hive HCatalog Check

    module.exports =  header: 'Hive Server2 Check', label_true: 'CHECKED', handler: (options) ->

## Assert Thrift TCP/HTTP Port

      @connection.wait
        header: 'Thrift'
        servers: options.wait.thrift

## Check JDBC

Note, the Hive Server2 is checked inside the beeline service. However, a very
basic test could be present here.

      @call header: 'Check JDBC', handler: ->
        # http://www.cloudera.com/content/cloudera-content/cloudera-docs/CDH4/4.3.0/CDH4-Security-Guide/cdh4sg_topic_9_1.html
        # !connect jdbc:hive2://master3.ryba:10001/default;principal=hive/master3.ryba@HADOOP.RYBA
        options.log? 'TODO: check hive server2 jdbc'
        # hive.server2.site['hive.zookeeper.quorum']
        # jdbc:hive2://<zookeeper_ensemble>;serviceDiscoveryMode=zooKeeper; zooKeeperNamespace=<hiveserver2_namespace
