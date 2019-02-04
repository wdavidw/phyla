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
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true
        ssl: module: 'masson/core/ssl', local: true
        java: module: 'masson/commons/java', local: true, recommanded: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, required: true
        hbase_master: module: '@rybajs/metal/hbase/master'
        # hbase_client: module: '@rybajs/metal/hbase/client', local: true, recommanded: true # Required if hbase_master
        hbase_client: module: '@rybajs/metal/hbase/client', local: true, auto: true # Required if hbase_master
        kafka_broker: module: '@rybajs/metal/kafka/broker'
        kafka_client: module: '@rybajs/metal/kafka/client', local: true, implicit: true, auto: true
        ranger_admin: module: '@rybajs/metal/ranger/admin', single: true
        ranger_kafka: module: '@rybajs/metal/ranger/plugins/kafka'
        ranger_hbase: module: '@rybajs/metal/ranger/plugins/hbase'
        solr_client: module: '@rybajs/metal/solr/client', local: true
        solr_cloud: module: '@rybajs/metal/solr/cloud'
        # solr_cloud_docker: module: '@rybajs/metal/solr/cloud_docker'
        # ranger_tagsync: module: '@rybajs/metal/ranger/tagsync'  # migration: wdavidw 171006, service does not exists
        atlas: module: '@rybajs/metal/atlas'
      configure:
        '@rybajs/metal/atlas/configure'
      commands:
        'install': [
          '@rybajs/metal/atlas/install'
          '@rybajs/metal/atlas/solr_bootstrap'
          '@rybajs/metal/atlas/start'
          '@rybajs/metal/atlas/check'
        ]
        'start':
          '@rybajs/metal/atlas/start'
        'status':
          '@rybajs/metal/atlas/status'
        'check':
          '@rybajs/metal/atlas/check'
        'stop':
          '@rybajs/metal/atlas/stop'

[atlas-apache]: http://atlas.incubator.apache.org
