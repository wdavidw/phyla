
# Ambari Server

[Ambari-server][Ambari-server] is the master host for ambari software.
Once logged into the ambari server host, the administrator can  provision, 
manage and monitor a Hadoop cluster.

    module.exports =
      use:
        ssl: implicit: true, module: 'masson/core/ssl'
        java: module: 'masson/commons/java', recommanded: true
        krb5_server: module: 'masson/core/krb5_server'
        db_admin: implicit: true, module: 'ryba/commons/db_admin'
        hadoop: 'ryba/hadoop/core'
        ambari_repo: 'ryba/ambari/repo'
        hdfs_nn: 'ryba/hadoop/hdfs_nn'
        yarn_rm: 'ryba/hadoop/yarn_rm'
        yarn_ts: 'ryba/hadoop/yarn_ts'
        hive_server2: 'ryba/hive/server2'
        oozie: 'ryba/oozie/server'
      configure: 'ryba/ambari/standalone/configure'
      commands:
        'ambari_blueprint': 'ryba/ambari/standalone/blueprint'
        'check': ->
          options = @config.ryba.ambari_standalone
          @call 'ryba/ambari/standalone/check', options
        'install': ->
          options = @config.ryba.ambari_standalone
          @call 'ryba/ambari/standalone/install', options
          @call 'ryba/ambari/standalone/start', options
          @call 'ryba/ambari/standalone/check', options
          @call 'ryba/ambari/views', options if options.views?.enabled
        'start': 'ryba/ambari/standalone/start'
        'stop': 'ryba/ambari/standalone/stop'

[Ambari-server]: http://ambari.apache.org
