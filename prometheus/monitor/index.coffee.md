
# Prometheus

Prometheus implements a highly dimensional data model. Time series are identified 
by a metric name and a set of key-value pairs.

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
        ssl: module: 'masson/core/ssl', local: true
        prometheus_monitor: module: 'ryba/prometheus/monitor'
        jmx_exporter_zookeeper: module: 'ryba/prometheus/jmx_exporters/zookeeper'
      configure:
        'ryba/prometheus/monitor/configure'
      commands:
        install: ->
          options  = @config.ryba.prometheus.monitor
          @call 'ryba/prometheus/monitor/install', options
          @call 'ryba/prometheus/monitor/start', options
          @call 'ryba/prometheus/monitor/check', options
        prepare : ->
          options  = @config.ryba.prometheus.monitor
          @call 'ryba/prometheus/monitor/prepare', options
