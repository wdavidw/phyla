
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
        db_admin: module: 'ryba/commons/db_admin', local: true, auto: true, implicit: true
        hadoop_core: module: 'ryba/hadoop/core', local: true
        ambari_repo: module: 'ryba/ambari/repo', local: true
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn'
        hdfs_dn: module: 'ryba/hadoop/hdfs_dn'
        yarn_ts: module: 'ryba/hadoop/yarn_ts'
        yarn_rm: module: 'ryba/hadoop/yarn_rm'
        yarn_nm: module: 'ryba/hadoop/yarn_nm'
        hive_server2: module: 'ryba/hive/server2'
        ranger_hive: module: 'ryba/ranger/plugins/hive'
        oozie_server: module: 'ryba/oozie/server'
        ambari_standalone: module: 'ryba/ambari/standalone'
      configure: 'ryba/ambari/standalone/configure'
      commands:
        'ambari_blueprint': 'ryba/ambari/standalone/blueprint'
        'check': 'ryba/ambari/standalone/check'
        'install': [
          'ryba/ambari/standalone/install'
          'ryba/ambari/standalone/start'
          'ryba/ambari/standalone/check'
          'ryba/ambari/views'
        ]
        'start': 'ryba/ambari/standalone/start'
        'stop': 'ryba/ambari/standalone/stop'

[Ambari-server]: http://ambari.apache.org
