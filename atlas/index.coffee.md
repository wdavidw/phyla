# Apache Atlas 

[Atlas][atlas-server] is a scalable and extensible set of core foundational
governance services – enabling enterprises to effectively and efficiently meet
their compliance requirements within Hadoop and allows integration with the whole
enterprise data ecosystem.

Atlas enables Hadoop users to manage more efficiently their data:

- Data Classification
- Centralized auditing
- Search & Lineage
- Scurity & Policy Engine

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true, recommanded: true
        zookeeper_server: module: 'ryba/zookeeper/server'
        hadoop_core: module: 'ryba/hadoop/core', local: true, required: true
        hbase_master: module: 'ryba/hbase/master'
        hbase_client: module: 'ryba/hbase/client', local: true, recommanded: true # Required if hbase_master
        hive_server2: module: 'ryba/hive/server2'
        hive_client: implicit: true, module: 'ryba/hive/client', local: true, recommanded: true
        kafka_broker: module: 'ryba/kafka/broker'
        ranger_tagsync: module: 'ryba/ranger/tagsync'  # migration: wdavidw 171006, service does not exists
        atlas: module: 'ryba/atlas'
      configure:
        'ryba/atlas/configure'
      commands:
        'install': ->
          options = @config.ryba.atlas
          @call 'ryba/atlas/install', options
          @call 'ryba/atlas/start', options
          @call 'ryba/atlas/check', options
        'start': ->
          options = @config.ryba.atlas
          @call 'ryba/atlas/start', options
        'status': ->
          options = @config.ryba.atlas
          @call 'ryba/atlas/status', options
        'check': ->
          options = @config.ryba.atlas
          @call 'ryba/atlas/check', options
        'stop': ->
          options = @config.ryba.atlas
          @call 'ryba/atlas/stop', options

[atlas-apache]: http://atlas.incubator.apache.org
