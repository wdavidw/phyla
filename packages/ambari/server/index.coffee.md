
# Ambari Server

[Ambari-server][Ambari-server] is the master host for ambari software.
Once logged into the ambari server host, the administrator can  provision, 
manage and monitor a Hadoop cluster.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        ssl: module: '@rybajs/tools/ssl', local: true, auto: true, implicit: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: '@rybajs/system/java', local: true, recommanded: true
        db_admin: module: '@rybajs/tools/db_admin', local: true, auto: true, implicit: true
        # hadoop_core: module: 'ryba/hadoop/core', local: true
        ambari_repo: module: '@rybajs/ambari/repo', local: true, auto: true, implicit: true
        ambari_server: module: '@rybajs/ambari/server'
      configure:
        '@rybajs/ambari/server/configure'
      commands:
        'prepare':
          '@rybajs/ambari/server/prepare'
        'ambari_blueprint':
          '@rybajs/ambari/server/blueprint'
        'check':
          '@rybajs/ambari/server/check'
        'install': [
          '@rybajs/ambari/server/install'
          # '@rybajs/ambari/server/start'
          # '@rybajs/ambari/server/check'
        ]
        'start':
          '@rybajs/ambari/server/start'
        'stop':
          '@rybajs/ambari/server/stop'

[Ambari-server]: http://ambari.apache.org
