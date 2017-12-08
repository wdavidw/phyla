# Apache Atlas 

[Atlas][atlas-server] Atlas is a scalable and extensible set of core foundational
governance services – enabling enterprises to effectively and efficiently meet
their compliance requirements within Hadoop and allows integration with the whole
enterprise data ecosystem.

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client'
        java: implicit: true, module: 'masson/commons/java'
        # solr_cloud: 'ryba/solr/cloud'
        solr_cloud_docker: module: 'ryba/solr/cloud_docker'
        server2: 'ryba/hive/server2'
        broker: 'ryba/kafka/broker'
        zookeepers: 'ryba/zookeeper/server'
        hbase_master: 'ryba/hbase/master'
        ranger_admin: 'ryba/ranger/admin'
        kafka_client: implicit: true, module: 'ryba/kafka/client'
        hive_client: implicit: true, module: 'ryba/hive/client'
        hbase_client: implicit: true, module: 'ryba/hbase/client'
      configure: [
        'ryba/atlas/configure'
        'ryba/ranger/plugins/atlas/configure'
        ]
      commands:
        'install': [
          'ryba/atlas/install'
          'ryba/atlas/start'
          'ryba/atlas/check'
        ]
        'start': 'ryba/atlas/start'
        'status': 'ryba/atlas/status'
        'check': 'ryba/atlas/check'
        'stop': 'ryba/atlas/stop'

[atlas-apache]: http://atlas.incubator.apache.org
