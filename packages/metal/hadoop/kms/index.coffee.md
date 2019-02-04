
# Hadoop KMS

Hadoop KMS is a cryptographic key management server based on Hadoop’s
KeyProvider API.

It provides a client and a server components which communicate over HTTP using a
REST API.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
      configure:
        '@rybajs/metal/hadoop/kms/configure'
      commands:
        'check':
          '@rybajs/metal/hadoop/kms/check'
        'install': [
          '@rybajs/metal/hadoop/kms/install'
          '@rybajs/metal/hadoop/kms/check'
        ]
