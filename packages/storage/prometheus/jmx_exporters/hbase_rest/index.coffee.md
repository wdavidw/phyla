
# JMX Exporter

JMX to Prometheus exporter.
A Collector that can configurably scrape and expose mBeans of a JMX target. 
It meant to be run as a Java Agent, exposing an HTTP server and scraping the local JVM.

    module.exports =
      deps:
        ssl: module: 'masson/core/ssl', local: true
        java: module: 'masson/commons/java', local: true, required: true
        iptables: module: 'masson/core/iptables', local: true
        hbase_rest: module: '@rybajs/metal/hbase/rest', local: true, required: true
        jmx_exporter: module: '@rybajs/storage/prometheus/jmx_exporters/hbase_rest'
        prometheus_monitor: module: '@rybajs/storage/prometheus/monitor', required: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true
      configure: '@rybajs/storage/prometheus/jmx_exporters/hbase_rest/configure'
      plugin: ({options}) ->
        @before
          action: ['service']
          name: 'hbase-rest'
        , ->
          delete options.original.action
          delete options.original.handler
          delete options.original.argument
          delete options.original.store
          @call '@rybajs/storage/prometheus/jmx_exporters/hbase_rest/password.coffee.md', options.original
      commands:
        install: [
          '@rybajs/storage/prometheus/jmx_exporters/hbase_rest/install'
          '@rybajs/storage/prometheus/jmx_exporters/hbase_rest/start'
        ]
        start : [
          '@rybajs/storage/prometheus/jmx_exporters/hbase_rest/start'
        ]
        stop : [
          '@rybajs/storage/prometheus/jmx_exporters/hbase_rest/stop'
        ]
        prepare: [
          '@rybajs/storage/prometheus/jmx_exporters/hbase_rest/prepare'
        ]
        password: [
          '@rybajs/storage/prometheus/jmx_exporters/hbase_rest/password.coffee.md'
        ]
