
# Solr
[Solr](http://lucene.apache.org/solr/standalone/) is highly reliable, scalable and fault tolerant, providing distributed indexing, replication and load-balanced querying, automated failover and recovery, centralized configuration and more.
Solr powers the search and navigation features of many of the world's largest internet sites'. 
Solr can be found [here](http://wwwftp.ciril.fr/pub/apache/lucene/solr/standalone/)

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client'
      configure:
        '@rybajs/metal/solr/standalone/configure'
      commands:
        'install': [
          '@rybajs/metal/solr/standalone/install'
          '@rybajs/metal/solr/standalone/start'
        ]
        'start': [
          '@rybajs/metal/solr/standalone/start'
        ]
        'stop': [
          '@rybajs/metal/solr/standalone/stop'
        ]
        'status': [
          '@rybajs/metal/solr/standalone/status'
        ]
        'prepare': [
          '@rybajs/metal/solr/standalone/prepare'
        ]
