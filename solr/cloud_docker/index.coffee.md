
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
        zookeeper_server: module: 'ryba/zookeeper/server', required: true
        hadoop_core: module: 'ryba/hadoop/core', local: true
        # hdfs_client: module: 'ryba/hadoop/hdfs_client', local: true
        swarm_agent: module: 'ryba/swarm/agent', local: true
        solr_cloud_docker: module: 'ryba/solr/cloud_docker'
      configure:
        'ryba/solr/cloud_docker/configure'
      commands:
        'prepare':
          'ryba/solr/cloud_docker/prepare'
        'install':
          'ryba/solr/cloud_docker/install'
