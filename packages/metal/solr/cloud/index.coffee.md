
# Solr Cloud

[Solr](http://lucene.apache.org/solr/standalone/) is highly reliable, scalable and fault tolerant, providing distributed indexing, replication and load-balanced querying, automated failover and recovery, centralized configuration and more.
Solr powers the search and navigation features of many of the world's largest internet sites'. 
Solr can be found [here](http://wwwftp.ciril.fr/pub/apache/lucene/solr/standalone/)

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        ssl: module: 'masson/core/ssl', local: true
        java: module: 'masson/commons/java', local: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server', required: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', required: true
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', local: true
        solr_cloud: module: '@rybajs/metal/solr/cloud'
      configure:
        '@rybajs/metal/solr/cloud/configure'
      commands:
        'prepare':
          '@rybajs/metal/solr/cloud/prepare'
        'install': [
          '@rybajs/metal/solr/cloud/install'
          '@rybajs/metal/solr/cloud/start'
          '@rybajs/metal/solr/cloud/check'
        ]
        'start':
          '@rybajs/metal/solr/cloud/start'
        'stop':
          '@rybajs/metal/solr/cloud/stop'
        'check': [
          '@rybajs/metal/solr/cloud/wait'
          '@rybajs/metal/solr/cloud/check'
        ]
