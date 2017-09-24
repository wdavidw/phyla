
# Ambari Server

[Ambari-server][Ambari-server] is the master host for ambari software.
Once logged into the ambari server host, the administrator can  provision, 
manage and monitor a Hadoop cluster.

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
        ssl: module: 'masson/core/ssl', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true, recommanded: true
        db_admin: module: 'ryba/commons/db_admin', local: true, auto: true, implicit: true
        hadoop_core: module: 'ryba/hadoop/core', local: true
        ambari_repo: module: 'ryba/ambari/repo', local: true, implicit: true
        ambari_server: module: 'ryba/ambari/server'
      configure: 'ryba/ambari/server/configure'
      # configure: ->
      #   require('./configure').call @, null, 'ambari_server'
      commands:
        'prepare': ->
          options = @config.ryba.ambaricserver
          @call 'ryba/ambari/server/prepare', options
        'ambari_blueprint': 'ryba/ambari/server/blueprint'
        'check': ->
          options = @config.ryba.ambari.server
          @call 'ryba/ambari/server/check', options
        'install': ->
          options = @config.ryba.ambari.server
          @call 'ryba/ambari/server/install', options
          @call 'ryba/ambari/server/start', options
          @call 'ryba/ambari/server/check', options
        'start': 'ryba/ambari/server/start'
        'stop': 'ryba/ambari/server/stop'

[Ambari-server]: http://ambari.apache.org
