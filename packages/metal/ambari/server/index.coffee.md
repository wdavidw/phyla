
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
        db_admin: module: '@rybajs/metal/commons/db_admin', local: true, auto: true, implicit: true
        # hadoop_core: module: '@rybajs/metal/hadoop/core', local: true
        ambari_repo: module: '@rybajs/metal/ambari/repo', local: true, implicit: true
        ambari_server: module: '@rybajs/metal/ambari/server'
      configure:
        '@rybajs/metal/ambari/server/configure'
      commands:
        'prepare':
          '@rybajs/metal/ambari/server/prepare'
        'ambari_blueprint':
          '@rybajs/metal/ambari/server/blueprint'
        'check':
          '@rybajs/metal/ambari/server/check'
        'install': [
          '@rybajs/metal/ambari/server/install'
          '@rybajs/metal/ambari/server/start'
          '@rybajs/metal/ambari/server/check'
        ]
        'start':
          '@rybajs/metal/ambari/server/start'
        'stop':
          '@rybajs/metal/ambari/server/stop'

[Ambari-server]: http://ambari.apache.org
