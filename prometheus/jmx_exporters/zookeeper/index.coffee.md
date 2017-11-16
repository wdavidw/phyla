
# JMX Exporter

JMX to Prometheus exporter.
A Collector that can configurably scrape and expose mBeans of a JMX target. 
It meant to be run as a Java Agent, exposing an HTTP server and scraping the local JVM.

    module.exports =
      deps:
        java: module: 'masson/commons/java', local: true, required: true
        iptables: module: 'masson/core/iptables', local: true
        zookeeper_server: module: 'ryba/zookeeper/server', local: true, required: true
        jmx_exporter: module: 'ryba/prometheus/jmx_exporters/zookeeper'
        hadoop_core: module: 'ryba/hadoop/core', local: true
        prometheus_monitor: module: 'ryba/prometheus/monitor', required: true
      configure: 'ryba/prometheus/jmx_exporters/zookeeper/configure'
      commands:
        install: [
          'ryba/prometheus/jmx_exporters/zookeeper/install'
          'ryba/prometheus/jmx_exporters/zookeeper/start'
        ]
        start : [
          'ryba/prometheus/jmx_exporters/zookeeper/start'
        ]
        stop : [
          'ryba/prometheus/jmx_exporters/zookeeper/stop'
        ]
        prepare: [
          'ryba/prometheus/jmx_exporters/zookeeper/prepare'
        ]
