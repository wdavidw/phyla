
# Zookeeper Server

Setting up a ZooKeeper server in standalone mode or in replicated mode.

A replicated group of servers in the same application is called a quorum, and in
replicated mode, all servers in the quorum have copies of the same configuration
file. The file is similar to the one used in standalone mode, but with a few
differences.

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        hdp: module: 'ryba/hdp', local: true
        zookeeper_server: module: 'ryba/zookeeper/server'
        # zoo_client: implicit: true, module: 'ryba/zookeeper/client'
      configure:
        'ryba/zookeeper/server/configure'
      commands:
        # 'backup':
        #   'ryba/zookeeper/server/backup'
        'check': ->
          options = @config.ryba.zookeeper
          @call 'ryba/zookeeper/server/check', options
        'install': ->
          options = @config.ryba.zookeeper
          @call 'ryba/zookeeper/server/install', options
          @call 'ryba/zookeeper/server/start', options
          @call 'ryba/zookeeper/server/check', options
        'start': ->
          options = @config.ryba.zookeeper
          @call 'ryba/zookeeper/server/start', options
        'status':
          'ryba/zookeeper/server/status'
        'stop': ->
          options = @config.ryba.zookeeper
          @call 'ryba/zookeeper/server/stop', options
