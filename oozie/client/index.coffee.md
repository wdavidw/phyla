
# Oozie Client

Oozie is a server based Workflow Engine specialized in running workflow jobs
with actions that run Hadoop Map/Reduce and Pig jobs.

The Oozie server installation includes the Oozie client. The Oozie client should
be installed in remote machines only.

    module.exports =
      use:
        ssl: module: 'masson/core/ssl', local: true
        java: module: 'masson/commons/java', local: true
        test_user: module: 'ryba/commons/test_user', local: true, auto: true, implicit: true
        krb5_client: implicit: true, module: 'masson/core/krb5_client'
        ranger_admin: module: 'ryba/ranger/admin', single: true
        ranger_hive: module: 'ryba/ranger/plugins/hiveserver2'
        hdfs_dn: module: 'ryba/hadoop/hdfs_dn'
        hdfs_client: module: 'ryba/hadoop/hdfs_client', local: true, auto: true, implicit: true
        yarn_rm: module: 'ryba/hadoop/yarn_rm'
        yarn_client: module: 'ryba/hadoop/yarn_client', local: true, auto: true, implicit: true
        mapred_client: module: 'ryba/hadoop/mapred_client', local: true, auto: true, implicit: true
        hive_server2: module: 'ryba/hive/server2'
        oozie_server: module: 'ryba/oozie/server'
      configure: 'ryba/oozie/client/configure'
      commands:
        'install': ->
          options = @config.ryba.oozie.client
          @call 'ryba/oozie/client/install', options
          @call 'ryba/oozie/client/check', options
        'check': ->
          options = @config.ryba.oozie.client
          @call 'ryba/oozie/client/check', options
