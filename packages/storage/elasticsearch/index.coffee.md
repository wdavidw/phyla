
# Elasticsearch

[Elasticsearch](http://www.elastic.co) is a higly-available, distributed  and scalable search Engine.
Elastic search is based on a restful api and indexes data with http Put requests.
It associated with kibana Logstash in order to visualizes data and transform it.
Hadoop being the place of big data , Elasticsearch integrates perfeclty into it.
Ryba can deploy Elasticsearch in the  secured Hadoop cluster.


Elastic search configuration for hadoop can be found at [Hortonworks Section](hortonworks.com/blog/configure-elastic-search-hadoop-hdp-2-0)

    module.exports =
      deps:
        java: implicit: true, module: 'masson/commons/java'
      configure:
        '@rybajs/storage/elasticsearch/configure'
      commands:
        'prepare':
          '@rybajs/storage/elasticsearch/prepare'
        'install': [
          '@rybajs/storage/elasticsearch/install'
          '@rybajs/storage/elasticsearch/start'
        ]
        'start':
          '@rybajs/storage/elasticsearch/start'
        'status':
          '@rybajs/storage/elasticsearch/status'
        'stop':
          '@rybajs/storage/elasticsearch/stop'
