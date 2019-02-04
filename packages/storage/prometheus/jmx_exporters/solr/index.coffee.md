
# JMX Exporter

JMX to Prometheus exporter.
A Collector that can configurably scrape and expose mBeans of a JMX target. 
It meant to be run as a Java Agent, exposing an HTTP server and scraping the local JVM.

    module.exports =
      deps:
        ssl: module: 'masson/core/ssl', local: true
        java: module: 'masson/commons/java', local: true, required: true
        iptables: module: 'masson/core/iptables', local: true
        solr: module: '@rybajs/metal/solr/cloud_docker', local: true, required: true
        jmx_exporter: module: '@rybajs/storage/prometheus/jmx_exporters/solr'
        prometheus_monitor: module: '@rybajs/storage/prometheus/monitor', required: true
      configure: '@rybajs/storage/prometheus/jmx_exporters/solr/configure'
      plugin: (options) ->
        @before
          action: ['service']
          name: 'solr-server'
        , ->
          delete options.original.action
          delete options.original.handler
          delete options.original.argument
          delete options.original.store
          @call '@rybajs/storage/prometheus/jmx_exporters/solr/password.coffee.md', options.original
      commands:
        install: [
          '@rybajs/storage/prometheus/jmx_exporters/solr/install'
          '@rybajs/storage/prometheus/jmx_exporters/solr/start'
        ]
        start : [
          '@rybajs/storage/prometheus/jmx_exporters/solr/start'
        ]
        stop : [
          '@rybajs/storage/prometheus/jmx_exporters/solr/stop'
        ]
        prepare: [
          '@rybajs/storage/prometheus/jmx_exporters/solr/prepare'
        ]
        password: [
         '@rybajs/storage/prometheus/jmx_exporters/solr/password.coffee.md'
        ]
