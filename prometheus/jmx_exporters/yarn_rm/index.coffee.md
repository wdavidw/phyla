
# JMX Exporter

JMX to Prometheus exporter.
A Collector that can configurably scrape and expose mBeans of a JMX target. 
It meant to be run as a Java Agent, exposing an HTTP server and scraping the local JVM.

    module.exports =
      deps:
        java: module: 'masson/commons/java', local: true, required: true
        iptables: module: 'masson/core/iptables', local: true
        yarn_rm: module: 'ryba/hadoop/yarn_rm', local: true, required: true
        jmx_exporter: module: 'ryba/prometheus/jmx_exporters/yarn_rm'
        prometheus_monitor: module: 'ryba/prometheus/monitor', required: true
        hadoop_core: module: 'ryba/hadoop/core', local: true
      configure: 'ryba/prometheus/jmx_exporters/yarn_rm/configure'
      commands:
        install: [
          'ryba/prometheus/jmx_exporters/yarn_rm/install'
          'ryba/prometheus/jmx_exporters/yarn_rm/start'
        ]
        start : [
          'ryba/prometheus/jmx_exporters/yarn_rm/start'
        ]
        stop : [
          'ryba/prometheus/jmx_exporters/yarn_rm/stop'
        ]
        prepare: [
          'ryba/prometheus/jmx_exporters/yarn_rm/prepare'
        ]
