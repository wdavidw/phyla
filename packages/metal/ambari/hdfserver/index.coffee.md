
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
        db_admin: module: '@rybajs/metal/commons/db_admin', local: true, auto: true, implicit: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true
        ambari_repo: module: '@rybajs/metal/ambari/hdfrepo', local: true, implicit: true
        ambari_hdfserver: module: '@rybajs/metal/ambari/hdfserver'
      configure: '@rybajs/metal/ambari/hdfserver/configure'
      # configure: ->
      #   require('../server/configure').call @, null, 'ambari_hdfserver'
      commands:
        'prepare': ->
          options = @config.ryba.ambari.hdfserver
          @call '@rybajs/metal/ambari/server/prepare', options
        'check': ->
          options = @config.ryba.ambari.hdfserver
          @call '@rybajs/metal/ambari/server/check', options
        'install': ->
          options = @config.ryba.ambari.hdfserver
          @call '@rybajs/metal/ambari/server/install', options
          @call '@rybajs/metal/ambari/server/start', options
          @call '@rybajs/metal/ambari/server/check', options
        'start': '@rybajs/metal/ambari/server/start'
        'stop': '@rybajs/metal/ambari/server/stop'

[Ambari-server]: http://ambari.apache.org
