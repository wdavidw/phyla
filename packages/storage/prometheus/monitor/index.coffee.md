
# Prometheus

Prometheus implements a highly dimensional data model. Time series are identified 
by a metric name and a set of key-value pairs.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        ssl: module: 'masson/core/ssl', local: true
        prometheus_monitor: module: '@rybajs/storage/prometheus/monitor'
      configure:
        '@rybajs/storage/prometheus/monitor/configure'
      commands:
        install: [
          '@rybajs/storage/prometheus/monitor/install'
          '@rybajs/storage/prometheus/monitor/start'
          '@rybajs/storage/prometheus/monitor/check'
        ]
        prepare: [
          '@rybajs/storage/prometheus/monitor/prepare'
        ]
        start: [
          '@rybajs/storage/prometheus/monitor/start'
        ]
