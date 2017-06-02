
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
        'start': 'ryba/ambari/standalone/start'
        'stop': 'ryba/ambari/standalone/stop'

[Ambari-server]: http://ambari.apache.org
