
# Prometheus JMX Exporter

JMX to Prometheus exporter.
A Collector that can configurably scrape and expose mBeans of a JMX target. 
It meant to be run as a Java Agent, exposing an HTTP server and scraping the local JVM.

    module.exports =
      use:
        java: module: 'masson/commons/java', local: true, required: true
        iptables: module: 'masson/core/iptables', local: true
        zookeeper_server: module: 'ryba/zookeeper/server', local: true, required: true
        jmx_exporter: module: 'ryba/prometheus/jmx_exporters/zookeeper'
        hadoop_core: module: 'ryba/hadoop/core', local: true
      configure: 'ryba/prometheus/jmx_exporters/zookeeper/configure'
      plugin: ->
        options = @config.ryba.prometheus.jmx_exporters.zookeeper
        @before
          type: ['service', 'start']
          name: 'zookeeper-server'
        , ->
          @call 'ryba/prometheus/jmx_exporters/zookeeper/install', options
        @after
          type: ['service', 'start']
          name: 'zookeeper-server'
        , ->
          @call 'ryba/prometheus/jmx_exporters/zookeeper/check', options
      commands:
        # install: ->
        #   options  = @config.ryba.prometheus.jmx_exporters.zookeeper
        #   @call 'ryba/prometheus/jmx_exporters/zookeeper/install', options
          # disable standalone mode
          # @call 'ryba/prometheus/jmx_exporters/zookeeper/start', options
        prepare : ->
          options  = @config.ryba.prometheus.jmx_exporters.zookeeper
          @call 'ryba/prometheus/jmx_exporters/zookeeper/prepare', options
