
# Solr cloud_docker on docker

[Solr](http://lucene.apache.org/solr/standalone/) is highly reliable, scalable and fault tolerant, providing distributed indexing, replication and load-balanced querying, automated failover and recovery, centralized configuration and more.
Solr powers the search and navigation features of many of the world's largest internet sites'. 
Solr can be found [here](http://wwwftp.ciril.fr/pub/apache/lucene/solr/standalone/)
This module enables adminstrator to manage severale solrcloud_docker instances running in docker containers.
For now it writes docker-compose.yml file, download resource files, create layout direcoties
but does not start the clusters.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        ssl: module: 'masson/core/ssl', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        docker: module: 'masson/commons/docker', required: true, local: true, auto: true
        java: module: 'masson/commons/java', local: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true
        # hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', local: true
        swarm_agent: module: '@rybajs/metal/swarm/agent', local: true
        solr_cloud_docker: module: '@rybajs/metal/solr/cloud_docker'
      configure:
        '@rybajs/metal/solr/cloud_docker/configure'
      commands:
        'prepare':
          '@rybajs/metal/solr/cloud_docker/prepare'
        'install':
          '@rybajs/metal/solr/cloud_docker/install'
