
# Zookeeper Server

Setting up a ZooKeeper server in standalone mode or in replicated mode.

A replicated group of servers in the same application is called a quorum, and in
replicated mode, all servers in the quorum have copies of the same configuration
file. The file is similar to the one used in standalone mode, but with a few
differences.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        hdp: module: 'ryba/hdp', local: true
        zookeeper_server: module: 'ryba/zookeeper/server'
        log4j: module: 'ryba/log4j', local: true
        # zoo_client: implicit: true, module: 'ryba/zookeeper/client'
      configure:
        'ryba/zookeeper/server/configure'
      commands:
        # 'backup':
        #   'ryba/zookeeper/server/backup'
        'check':
          'ryba/zookeeper/server/check'
        'install': [
          'ryba/zookeeper/server/install'
          'ryba/zookeeper/server/start'
          'ryba/zookeeper/server/check'
        ]
        'start':
          'ryba/zookeeper/server/start'
        'status':
          'ryba/zookeeper/server/status'
        'stop':
          'ryba/zookeeper/server/stop'
