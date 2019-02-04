
# Elasticsearch (Docker)

[Elasticsearch](http://www.elastic.co) is a higly-available, distributed  and scalable search Engine.
Elastic search is based on a restful api and indexes data with http Put requests.
It associated with kibana Logstash in order to visualizes data and transform it.
Hadoop being the place of big data , Elasticsearch integrates perfeclty into it.
Ryba can deploy Elasticsearch in the  secured Hadoop cluster.

Elastic search configuration for hadoop can be found at [Hortonworks Section](hortonworks.com/blog/configure-elastic-search-hadoop-hdp-2-0)

    module.exports =
      deps:
        docker: module: 'masson/commons/docker', local: true
        iptables: module: 'masson/core/iptables', local: true
        ssl: module: 'masson/core/ssl', local: true
        esdocker: module: '@rybajs/metal/esdocker'
        swarm_manager: module: '@rybajs/metal/swarm/manager'
      configure:
        '@rybajs/metal/esdocker/configure'
      commands:
        'install': [
          '@rybajs/metal/esdocker/install'
        ]
        'prepare':
          '@rybajs/metal/esdocker/prepare'
