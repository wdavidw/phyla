
# Solr Cloud

[Solr](http://lucene.apache.org/solr/standalone/) is highly reliable, scalable and fault tolerant, providing distributed indexing, replication and load-balanced querying, automated failover and recovery, centralized configuration and more.
Solr powers the search and navigation features of many of the world's largest internet sites'. 
Solr can be found [here](http://wwwftp.ciril.fr/pub/apache/lucene/solr/standalone/)

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        ssl: module: 'masson/core/ssl', local: true
        java: module: 'masson/commons/java', local: true
        zookeeper_server: module: 'ryba/zookeeper/server', required: true
        hadoop_core: module: 'ryba/hadoop/core', required: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', local: true
        solr_cloud: module: 'ryba/solr/cloud'
      configure: 'ryba/solr/cloud/configure'
      commands:
        'prepare': ->
          options = @config.ryba.solr.cloud
          @call 'ryba/solr/cloud/prepare', options
        'install': ->
          options = @config.ryba.solr.cloud
          @call 'ryba/solr/cloud/install', options
          @call 'ryba/solr/cloud/start', options
          @call 'ryba/solr/cloud/check', options
        'start': ->
          options = @config.ryba.solr.cloud
          @call 'ryba/solr/cloud/start', options
        'stop': ->
          options = @config.ryba.solr.cloud
          @call 'ryba/solr/cloud/stop', options
        'check': ->
          options = @config.ryba.solr.cloud
          @call 'ryba/solr/cloud/wait', options
          @call 'ryba/solr/cloud/check', options
