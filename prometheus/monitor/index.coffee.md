
# Prometheus

Prometheus implements a highly dimensional data model. Time series are identified 
by a metric name and a set of key-value pairs.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        ssl: module: 'masson/core/ssl', local: true
        prometheus_monitor: module: 'ryba/prometheus/monitor'
      configure:
        'ryba/prometheus/monitor/configure'
      commands:
        install: [
          'ryba/prometheus/monitor/install'
          'ryba/prometheus/monitor/start'
          'ryba/prometheus/monitor/check'
        ]
        prepare: [
          'ryba/prometheus/monitor/prepare'
        ]
        start: [
          'ryba/prometheus/monitor/start'
        ]
