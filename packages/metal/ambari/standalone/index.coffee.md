
# Ambari Server

[Ambari-server][Ambari-server] is the master host for ambari software.
Once logged into the ambari server host, the administrator can  provision, 
manage and monitor a Hadoop cluster.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        ssl: module: 'masson/core/ssl', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        db_admin: module: '@rybajs/metal/commons/db_admin', local: true, auto: true, implicit: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true
        ambari_repo: module: '@rybajs/metal/ambari/repo', local: true
        hdfs_nn: module: '@rybajs/metal/hadoop/hdfs_nn'
        hdfs_dn: module: '@rybajs/metal/hadoop/hdfs_dn'
        yarn_ts: module: '@rybajs/metal/hadoop/yarn_ts'
        yarn_rm: module: '@rybajs/metal/hadoop/yarn_rm'
        yarn_nm: module: '@rybajs/metal/hadoop/yarn_nm'
        hive_server2: module: '@rybajs/metal/hive/server2'
        ranger_hive: module: '@rybajs/metal/ranger/plugins/hive'
        oozie_server: module: '@rybajs/metal/oozie/server'
        ambari_standalone: module: '@rybajs/metal/ambari/standalone'
      configure: '@rybajs/metal/ambari/standalone/configure'
      commands:
        'ambari_blueprint': '@rybajs/metal/ambari/standalone/blueprint'
        'check': '@rybajs/metal/ambari/standalone/check'
        'install': [
          '@rybajs/metal/ambari/standalone/install'
          '@rybajs/metal/ambari/standalone/start'
          '@rybajs/metal/ambari/standalone/check'
          '@rybajs/metal/ambari/views'
        ]
        'start': '@rybajs/metal/ambari/standalone/start'
        'stop': '@rybajs/metal/ambari/standalone/stop'

[Ambari-server]: http://ambari.apache.org
