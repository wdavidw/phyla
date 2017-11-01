
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
        use:
          krb5_client: implicit: true, module: 'masson/core/krb5_client', local: true
          iptables: module: 'masson/core/iptables', local: true
          ssl: module: 'masson/core/ssl', local: true
          java: module: 'masson/commons/java', local: true
          hadoop_core: 'ryba/hadoop/core'
          openldap_server:  module: 'masson/core/openldap_server'
          zookeeper_server: module: 'ryba/zookeeper/server'
          nifi: module: 'ryba/nifi'
          hdf: 'ryba/hdf'
          log4j: module: 'ryba/log4j', local: true
        configure:
          'ryba/nifi/configure'
        commands:
          'install': ->
            options = @config.ryba.nifi
            @call 'ryba/nifi/install', options
            @call 'ryba/nifi/start', options
            @call 'ryba/nifi/check', options
          'check': ->
            options = @config.ryba.nifi
            @call 'ryba/nifi/check', options
          'prepare': ->
            options = @config.ryba.nifi
            @call 'ryba/nifi/prepare', options
          'status': ->
            options = @config.ryba.nifi
            @call 'ryba/nifi/status', options
          'start': ->
            options = @config.ryba.nifi
            @call 'ryba/nifi/start', options
          'stop': ->
            options = @config.ryba.nifi
            @call 'ryba/nifi/stop', options
