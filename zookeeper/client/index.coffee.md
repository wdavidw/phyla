
# Zookeeper Client

    module.exports =
      use:
        java: module: 'masson/commons/java', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        test_user: module: 'ryba/commons/test_user', local: true
        hdp: module: 'ryba/hdp', local: true
        zookeeper_server: module: 'ryba/zookeeper/server'
      configure:
        'ryba/zookeeper/client/configure'
      commands:
        'check': ->
          options = @config.ryba.zookeeper_client
          @call 'ryba/zookeeper/client/check', options
        'install': ->
          options = @config.ryba.zookeeper_client
          @call 'ryba/zookeeper/client/install', options
          @call 'ryba/zookeeper/client/check', options
