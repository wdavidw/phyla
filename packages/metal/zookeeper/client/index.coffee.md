
# Zookeeper Client

    module.exports =
      deps:
        java: module: 'masson/commons/java', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        test_user: module: '@rybajs/metal/commons/test_user', local: true
        hdp: module: '@rybajs/metal/hdp', local: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
      configure:
        '@rybajs/metal/zookeeper/client/configure'
      commands:
        'check':
          '@rybajs/metal/zookeeper/client/check'
        'install': [
          '@rybajs/metal/zookeeper/client/install'
          '@rybajs/metal/zookeeper/client/check'
        ]
