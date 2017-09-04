
# Hadoop KMS

Hadoop KMS is a cryptographic key management server based on Hadoop’s
KeyProvider API.

It provides a client and a server components which communicate over HTTP using a
REST API.

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        zookeeper_server: module: 'ryba/zookeeper/server'
      configure:
        'ryba/hadoop/kms/configure'
      commands:
        'check': ->
          options = @config.ryba.kms
          @call 'ryba/hadoop/kms/check', options
        'install': ->
          options = @config.ryba.kms
          @call 'ryba/hadoop/kms/install', options
          @call 'ryba/hadoop/kms/check', options
