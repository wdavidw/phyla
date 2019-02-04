
# NiFi

Apache NiFi supports powerful and scalable directed graphs of data routing,
transformation, and system mediation logic. Some of the high-level capabilities 
and objectives of NiFi includes:
  * Web-based user interface
  * Highly configurable
  * Data Provenance
  * Designed for extension
  * SSL, SSH, HTTPS, encrypted content, etc...

      module.exports =
        deps:
          krb5_client: implicit: true, module: 'masson/core/krb5_client', local: true
          iptables: module: 'masson/core/iptables', local: true
          ssl: module: 'masson/core/ssl', local: true
          java: module: 'masson/commons/java', local: true
          hadoop_core: '@rybajs/metal/hadoop/core'
          openldap_server:  module: 'masson/core/openldap_server'
          zookeeper_server: module: '@rybajs/metal/zookeeper/server'
          nifi: module: '@rybajs/metal/nifi'
          hdf: '@rybajs/metal/hdf'
          log4j: module: '@rybajs/metal/log4j', local: true
        configure:
          '@rybajs/metal/nifi/configure'
        commands:
          'install': [
            '@rybajs/metal/nifi/install'
            '@rybajs/metal/nifi/start'
            '@rybajs/metal/nifi/check'
          ]
          'check':
            '@rybajs/metal/nifi/check'
          'prepare':
            '@rybajs/metal/nifi/prepare'
          'status':
            '@rybajs/metal/nifi/status'
          'start':
            '@rybajs/metal/nifi/start'
          'stop':
            '@rybajs/metal/nifi/stop'
