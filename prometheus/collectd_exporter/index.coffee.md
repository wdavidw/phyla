
# Collectd Exporter

A [Collector](https://github.com/prometheus/collectd_exporter) which accepts collectd's
 binary network protocol as sent by collectd's network plugin and metrics in JSON 
 format via HTTP POST as sent by collectd's write_http plugin, and transforms and 
 exposes them for consumption by Prometheus.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        collectd: module: 'ryba/collectd', local: true, required: true
        collectd_exporter: module: 'ryba/prometheus/collectd_exporter'
        prometheus_monitor: module: 'ryba/prometheus/monitor', required: true
      configure: 'ryba/prometheus/collectd_exporter/configure'
      commands:
        install: [
          'ryba/prometheus/collectd_exporter/install'
          'ryba/prometheus/collectd_exporter/start'
        ]
        start : [
          'ryba/prometheus/collectd_exporter/start'
        ]
        stop : [
          'ryba/prometheus/collectd_exporter/stop'
        ]
        prepare: [
          'ryba/prometheus/collectd_exporter/prepare'
        ]
