
# JMX Exporter

JMX to Prometheus exporter.
A Collector that can configurably scrape and expose mBeans of a JMX target. 
It meant to be run as a Java Agent, exposing an HTTP server and scraping the local JVM.

    module.exports =
      deps:
        java: module: 'masson/commons/java', local: true, required: true
        iptables: module: 'masson/core/iptables', local: true
        yarn_nm: module: '@rybajs/metal/hadoop/yarn_nm', local: true, required: true
        jmx_exporter: module: '@rybajs/storage/prometheus/jmx_exporters/yarn_nm'
        prometheus_monitor: module: '@rybajs/storage/prometheus/monitor', required: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true
      configure: '@rybajs/storage/prometheus/jmx_exporters/yarn_nm/configure'
      plugin: ({options}) ->
        @before
          action: ['service']
          name: 'hadoop-yarn-nodemanager'
        , ->
          delete options.original.action
          delete options.original.handler
          delete options.original.argument
          delete options.original.store
          @call '@rybajs/storage/prometheus/jmx_exporters/yarn_nm/password.coffee.md', options.original
      commands:
        install: [
          '@rybajs/storage/prometheus/jmx_exporters/yarn_nm/install'
          '@rybajs/storage/prometheus/jmx_exporters/yarn_nm/start'
        ]
        start : [
          '@rybajs/storage/prometheus/jmx_exporters/yarn_nm/start'
        ]
        stop : [
          '@rybajs/storage/prometheus/jmx_exporters/yarn_nm/stop'
        ]
        prepare: [
          '@rybajs/storage/prometheus/jmx_exporters/yarn_nm/prepare'
        ]
