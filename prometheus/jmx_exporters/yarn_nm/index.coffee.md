
# JMX Exporter

JMX to Prometheus exporter.
A Collector that can configurably scrape and expose mBeans of a JMX target. 
It meant to be run as a Java Agent, exposing an HTTP server and scraping the local JVM.

    module.exports =
      deps:
        java: module: 'masson/commons/java', local: true, required: true
        iptables: module: 'masson/core/iptables', local: true
        yarn_nm: module: 'ryba/hadoop/yarn_nm', local: true, required: true
        jmx_exporter: module: 'ryba/prometheus/jmx_exporters/yarn_nm'
        prometheus_monitor: module: 'ryba/prometheus/monitor', required: true
        hadoop_core: module: 'ryba/hadoop/core', local: true
      configure: 'ryba/prometheus/jmx_exporters/yarn_nm/configure'
      commands:
        install: [
          'ryba/prometheus/jmx_exporters/yarn_nm/install'
          'ryba/prometheus/jmx_exporters/yarn_nm/start'
        ]
        start : [
          'ryba/prometheus/jmx_exporters/yarn_nm/start'
        ]
        stop : [
          'ryba/prometheus/jmx_exporters/yarn_nm/stop'
        ]
        prepare: [
          'ryba/prometheus/jmx_exporters/yarn_nm/prepare'
        ]
