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
        ssl: module: 'masson/core/ssl', local: true
        java: module: 'masson/commons/java', local: true, recommanded: true
        zookeeper_server: module: 'ryba/zookeeper/server'
        hadoop_core: module: 'ryba/hadoop/core', local: true, required: true
        hbase_master: module: 'ryba/hbase/master'
        hbase_client: module: 'ryba/hbase/client', local: true, recommanded: true # Required if hbase_master
        kafka_broker: module: 'ryba/kafka/broker'
        kafka_client: module: 'ryba/kafka/client', local: true, implicit: true, auto: true
        ranger_admin: module: 'ryba/ranger/admin', single: true
        ranger_kafka: module: 'ryba/ranger/plugins/kafka'
        ranger_hbase: module: 'ryba/ranger/plugins/hbase'
        solr_client: module: 'ryba/solr/client', local: true
        solr_cloud: module: 'ryba/solr/cloud'
        # solr_cloud_docker: module: 'ryba/solr/cloud_docker'
        # ranger_tagsync: module: 'ryba/ranger/tagsync'  # migration: wdavidw 171006, service does not exists
        atlas: module: 'ryba/atlas'
      configure:
        'ryba/atlas/configure'
      commands:
        'install': ->
          options = @config.ryba.atlas
          @call 'ryba/atlas/install', options
          @call 'ryba/atlas/solr_bootstrap', options
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
