
# Ambari Server

[Ambari-server][Ambari-server] is the master host for ambari software.
Once logged into the ambari server host, the administrator can  provision, 
manage and monitor a Hadoop cluster.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        ssl: module: 'masson/core/ssl', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true, recommanded: true
        db_admin: module: 'ryba/commons/db_admin', local: true, auto: true, implicit: true
        hadoop_core: module: 'ryba/hadoop/core', local: true
        ambari_repo: module: 'ryba/ambari/repo', local: true, implicit: true
        ambari_server: module: 'ryba/ambari/server'
      configure:
        'ryba/ambari/server/configure'
      commands:
        'prepare':
          'ryba/ambari/server/prepare'
        'ambari_blueprint':
          'ryba/ambari/server/blueprint'
        'check':
          'ryba/ambari/server/check'
        'install': [
          'ryba/ambari/server/install'
          'ryba/ambari/server/start'
          'ryba/ambari/server/check'
        ]
        'start':
          'ryba/ambari/server/start'
        'stop':
          'ryba/ambari/server/stop'

[Ambari-server]: http://ambari.apache.org
