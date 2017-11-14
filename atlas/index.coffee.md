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
        zookeeper_server: module: 'ryba/zookeeper/server'
        hadoop_core: module: 'ryba/hadoop/core', local: true, required: true
        hbase_master: module: 'ryba/hbase/master'
        # hbase_client: module: 'ryba/hbase/client', local: true, recommanded: true # Required if hbase_master
        hbase_client: module: 'ryba/hbase/client', local: true, auto: true # Required if hbase_master
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
        'install': [
          'ryba/atlas/install'
          'ryba/atlas/solr_bootstrap'
          'ryba/atlas/start'
          'ryba/atlas/check'
        ]
        'start':
          'ryba/atlas/start'
        'status':
          'ryba/atlas/status'
        'check':
          'ryba/atlas/check'
        'stop':
          'ryba/atlas/stop'

[atlas-apache]: http://atlas.incubator.apache.org
