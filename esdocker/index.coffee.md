
# Elasticsearch (Docker)

[Elasticsearch](http://www.elastic.co) is a higly-available, distributed  and scalable search Engine.
Elastic search is based on a restful api and indexes data with http Put requests.
It associated with kibana Logstash in order to visualizes data and transform it.
Hadoop being the place of big data , Elasticsearch integrates perfeclty into it.
Ryba can deploy Elasticsearch in the  secured Hadoop cluster.

Elastic search configuration for hadoop can be found at [Hortonworks Section](hortonworks.com/blog/configure-elastic-search-hadoop-hdp-2-0)

    module.exports =
      use: {}
        iptables: module: 'masson/core/iptables', local: true
        ssl: module: 'masson/core/ssl', local: true
        esdocker: module: 'ryba/esdocker'
      configure:
        'ryba/esdocker/configure'
      commands:
        'install': ->
          options = @config.ryba.esdocker
          @call 'ryba/esdocker/prepare', options
          @call 'ryba/esdocker/install', options
        'prepare': ->
          options = @config.ryba.esdocker
          @call 'ryba/esdocker/prepare', options
