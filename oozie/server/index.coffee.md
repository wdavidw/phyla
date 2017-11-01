
# Oozie Server

[Oozie Server][Oozie] is a server based Workflow Engine specialized in running workflow jobs.
Workflows are basically collections of actions.
These actions can be  Hadoop Map/Reduce jobs, Pig jobs arranged in a control dependency DAG (Direct Acyclic Graph).
Please check Oozie page

    module.exports =
      use:
        ssl: module: 'masson/core/ssl', local: true
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        db_admin: module: 'ryba/commons/db_admin', local: true, auto: true, implicit: true
        zookeeper_server: module: 'ryba/zookeeper/server'
        hadoop_core: module: 'ryba/hadoop/core', local: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', local: true
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn'
        hdfs_dn: module: 'ryba/hadoop/hdfs_dn'
        yarn_rm: module: 'ryba/hadoop/yarn_rm'
        yarn_nm: module: 'ryba/hadoop/yarn_nm'
        hbase_master: module: 'ryba/hbase/master'
        hive_hcatalog: module: 'ryba/hive/hcatalog'
        hive_server2: module: 'ryba/hive/server2'
        hive_webhcat: module: 'ryba/hive/webhcat'
        spark_client: module: 'ryba/spark/client', local: true, auto: true, implicit: true
        oozie_server: module: 'ryba/oozie/server'
        log4j: module: 'ryba/log4j', local: true
      configure: 'ryba/oozie/server/configure'
      commands:
        backup: ->
          options = @config.ryba.oozie.server
          @call 'ryba/oozie/server/backup', options
        install: ->
          options = @config.ryba.oozie.server
          @call 'ryba/oozie/server/install', options
          @call 'ryba/oozie/server/start', options
          @call 'ryba/oozie/server/check', options
        start: ->
          options = @config.ryba.oozie.server
          @call 'ryba/oozie/server/start', options
          @call 'ryba/oozie/server/check', options
        status: ->
          options = @config.ryba.oozie.server
          @call 'ryba/oozie/server/status', options
        stop: ->
          options = @config.ryba.oozie.server
          @call 'ryba/oozie/server/stop', options

[Oozie]: https://oozie.apache.org/docs/3.1.3-incubating/index.html
