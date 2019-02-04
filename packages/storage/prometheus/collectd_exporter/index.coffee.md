
# Collectd Exporter

A [Collector](https://github.com/prometheus/collectd_exporter) which accepts collectd's
 binary network protocol as sent by collectd's network plugin and metrics in JSON 
 format via HTTP POST as sent by collectd's write_http plugin, and transforms and 
 exposes them for consumption by Prometheus.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        collectd: module: '@rybajs/metal/collectd', local: true, required: true
        collectd_exporter: module: '@rybajs/storage/prometheus/collectd_exporter'
        prometheus_monitor: module: '@rybajs/storage/prometheus/monitor', required: true
      configure: '@rybajs/storage/prometheus/collectd_exporter/configure'
      commands:
        install: [
          '@rybajs/storage/prometheus/collectd_exporter/install'
          '@rybajs/storage/prometheus/collectd_exporter/start'
        ]
        start : [
          '@rybajs/storage/prometheus/collectd_exporter/start'
        ]
        stop : [
          '@rybajs/storage/prometheus/collectd_exporter/stop'
        ]
        prepare: [
          '@rybajs/storage/prometheus/collectd_exporter/prepare'
        ]
