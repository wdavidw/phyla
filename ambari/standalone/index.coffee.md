
# Ambari Server

[Ambari-server][Ambari-server] is the master host for ambari software.
Once logged into the ambari server host, the administrator can  provision, 
manage and monitor a Hadoop cluster.

    module.exports =
      use:
        ssl: module: 'masson/core/ssl', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        db_admin: module: 'ryba/commons/db_admin', local: true, auto: true, implicit: true
        hadoop_core: 'ryba/hadoop/core', local: true
        ambari_repo: 'ryba/ambari/repo', local: true
        hdfs_nn: 'ryba/hadoop/hdfs_nn'
        hdfs_dn: 'ryba/hadoop/hdfs_dn'
        yarn_ts: 'ryba/hadoop/yarn_ts'
        yarn_rm: 'ryba/hadoop/yarn_rm'
        yarn_nm: 'ryba/hadoop/yarn_nm'
        hive_server2: 'ryba/hive/server2'
        ranger_hive: 'ryba/ranger/plugins/hive'
        oozie_server: 'ryba/oozie/server'
      configure: 'ryba/ambari/standalone/configure'
      commands:
        'ambari_blueprint': 'ryba/ambari/standalone/blueprint'
        'check': ->
          options = @config.ryba.ambari.standalone
          @call 'ryba/ambari/standalone/check', options
        'install': ->
          options = @config.ryba.ambari.standalone
          @call 'ryba/ambari/standalone/install', options
          @call 'ryba/ambari/standalone/start', options
          @call 'ryba/ambari/standalone/check', options
          @call 'ryba/ambari/views', options if options.views?.enabled
        'start': 'ryba/ambari/standalone/start'
        'stop': 'ryba/ambari/standalone/stop'

[Ambari-server]: http://ambari.apache.org
