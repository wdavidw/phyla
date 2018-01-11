
# Logstash

[Logstash](https://www.elastic.co/products/logstash) Logstash is an open source, server-side data processing pipeline that ingests data from a multitude of sources simultaneously, transforms it, and then sends it to your favorite “stash.”

    module.exports =
      deps:
        java: implicit: true, module: 'masson/commons/java'
        solr_client: module: 'ryba/solr/client', local: true
        iptables: module: 'masson/core/iptables', local: true
      configure:
        'ryba/elasticsearch/logstash/configure'
      commands:
        'prepare':
          'ryba/elasticsearch/logstash/prepare'
        'install': [
          'ryba/elasticsearch/logstash/solr_bootstrap'
          'ryba/elasticsearch/logstash/install'
          'ryba/elasticsearch/logstash/start'
        ]
        'start':
          'ryba/elasticsearch/logstash/start'
        'status':
          'ryba/elasticsearch/logstash/status'
        'stop':
          'ryba/elasticsearch/logstash/stop'
