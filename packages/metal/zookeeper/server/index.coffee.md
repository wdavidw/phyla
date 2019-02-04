
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
        hdp: module: '@rybajs/metal/hdp', local: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
        log4j: module: '@rybajs/metal/log4j', local: true
        # zoo_client: implicit: true, module: '@rybajs/metal/zookeeper/client'
      configure:
        '@rybajs/metal/zookeeper/server/configure'
      commands:
        # 'backup':
        #   '@rybajs/metal/zookeeper/server/backup'
        'check':
          '@rybajs/metal/zookeeper/server/check'
        'install': [
          '@rybajs/metal/zookeeper/server/install'
          '@rybajs/metal/zookeeper/server/start'
          '@rybajs/metal/zookeeper/server/check'
        ]
        'start':
          '@rybajs/metal/zookeeper/server/start'
        'status':
          '@rybajs/metal/zookeeper/server/status'
        'stop':
          '@rybajs/metal/zookeeper/server/stop'
