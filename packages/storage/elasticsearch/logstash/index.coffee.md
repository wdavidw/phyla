
# Logstash

[Logstash](https://www.elastic.co/products/logstash) Logstash is an open source, server-side data processing pipeline that ingests data from a multitude of sources simultaneously, transforms it, and then sends it to your favorite “stash.”

    module.exports =
      deps:
        java: implicit: true, module: 'masson/commons/java'
        solr_client: module: '@rybajs/metal/solr/client', local: true
        iptables: module: 'masson/core/iptables', local: true
      configure:
        '@rybajs/storage/elasticsearch/logstash/configure'
      commands:
        'prepare':
          '@rybajs/storage/elasticsearch/logstash/prepare'
        'install': [
          '@rybajs/storage/elasticsearch/logstash/solr_bootstrap'
          '@rybajs/storage/elasticsearch/logstash/install'
          '@rybajs/storage/elasticsearch/logstash/start'
        ]
        'start':
          '@rybajs/storage/elasticsearch/logstash/start'
        'status':
          '@rybajs/storage/elasticsearch/logstash/status'
        'stop':
          '@rybajs/storage/elasticsearch/logstash/stop'
