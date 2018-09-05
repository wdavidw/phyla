
# JMX Exporter

JMX to Prometheus exporter.
A Collector that can configurably scrape and expose mBeans of a JMX target. 
It meant to be run as a Java Agent, exposing an HTTP server and scraping the local JVM.

    module.exports =
      deps:
        java: module: 'masson/commons/java', local: true, required: true
        iptables: module: 'masson/core/iptables', local: true
        hdfs_jn: module: 'ryba/hadoop/hdfs_jn', local: true, required: true
        jmx_exporter: module: 'ryba/prometheus/jmx_exporters/hdfs_jn'
        prometheus_monitor: module: 'ryba/prometheus/monitor', required: true
        hadoop_core: module: 'ryba/hadoop/core', local: true
      configure: 'ryba/prometheus/jmx_exporters/hdfs_jn/configure'
      plugin: ({options}) ->
        @before
          action: ['service']
          name: 'hadoop-hdfs-journalnode'
        , ->
          delete options.original.action
          delete options.original.handler
          delete options.original.argument
          delete options.original.store
          @call 'ryba/prometheus/jmx_exporters/hdfs_jn/password.coffee.md', options.original
      commands:
        install: [
          'ryba/prometheus/jmx_exporters/hdfs_jn/install'
          'ryba/prometheus/jmx_exporters/hdfs_jn/start'
        ]
        start : [
          'ryba/prometheus/jmx_exporters/hdfs_jn/start'
        ]
        stop : [
          'ryba/prometheus/jmx_exporters/hdfs_jn/stop'
        ]
        prepare: [
          'ryba/prometheus/jmx_exporters/hdfs_jn/prepare'
        ]
