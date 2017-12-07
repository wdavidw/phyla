
# JMX Exporter

JMX to Prometheus exporter.
A Collector that can configurably scrape and expose mBeans of a JMX target. 
It meant to be run as a Java Agent, exposing an HTTP server and scraping the local JVM.

    module.exports =
      deps:
        java: module: 'masson/commons/java', local: true, required: true
        iptables: module: 'masson/core/iptables', local: true
        hbase_master: module: 'ryba/hbase/master', local: true, required: true
        jmx_exporter: module: 'ryba/prometheus/jmx_exporters/hbase_master'
        prometheus_monitor: module: 'ryba/prometheus/monitor', required: true
        hadoop_core: module: 'ryba/hadoop/core', local: true
      configure: 'ryba/prometheus/jmx_exporters/hbase_master/configure'
      commands:
        install: [
          'ryba/prometheus/jmx_exporters/hbase_master/install'
          'ryba/prometheus/jmx_exporters/hbase_master/start'
        ]
        start : [
          'ryba/prometheus/jmx_exporters/hbase_master/start'
        ]
        stop : [
          'ryba/prometheus/jmx_exporters/hbase_master/stop'
        ]
        prepare: [
          'ryba/prometheus/jmx_exporters/hbase_master/prepare'
        ]
