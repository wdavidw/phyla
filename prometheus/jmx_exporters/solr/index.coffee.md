
# JMX Exporter

JMX to Prometheus exporter.
A Collector that can configurably scrape and expose mBeans of a JMX target. 
It meant to be run as a Java Agent, exposing an HTTP server and scraping the local JVM.

    module.exports =
      deps:
        ssl: module: 'masson/core/ssl', local: true
        java: module: 'masson/commons/java', local: true, required: true
        iptables: module: 'masson/core/iptables', local: true
        solr: module: 'ryba/solr/cloud_docker', local: true, required: true
        jmx_exporter: module: 'ryba/prometheus/jmx_exporters/solr'
        prometheus_monitor: module: 'ryba/prometheus/monitor', required: true
      configure: 'ryba/prometheus/jmx_exporters/solr/configure'
      plugin: (options) ->
        @before
          action: ['service']
          name: 'solr-server'
        , ->
          delete options.original.action
          delete options.original.handler
          delete options.original.argument
          delete options.original.store
          @call 'ryba/prometheus/jmx_exporters/solr/password.coffee.md', options.original
      commands:
        install: [
          'ryba/prometheus/jmx_exporters/solr/install'
          'ryba/prometheus/jmx_exporters/solr/start'
        ]
        start : [
          'ryba/prometheus/jmx_exporters/solr/start'
        ]
        stop : [
          'ryba/prometheus/jmx_exporters/solr/stop'
        ]
        prepare: [
          'ryba/prometheus/jmx_exporters/solr/prepare'
        ]
        password: [
         'ryba/prometheus/jmx_exporters/solr/password.coffee.md'
        ]
