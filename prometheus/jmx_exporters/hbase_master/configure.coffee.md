
# Configure JMX Exporter HBase Master

    module.exports = (service) ->
      options = service.options

## Identities

      options.hadoop_group = service.deps.hadoop_core.options.hadoop_group
      # Group
      options.group ?= merge {}, service.deps.prometheus_monitor[0].options.group, options.group
      options.user ?= merge {}, service.deps.prometheus_monitor[0].options.user, options.user

## Package
    
      options.version ?= '0.1.0'
      #standalone server
      options.jar_source ?= "https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_httpserver/#{options.version}/jmx_prometheus_httpserver-#{options.version}-jar-with-dependencies.jar"
      # java agent
      # options.agent_source ?= "https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/#{options.version}/jmx_prometheus_javaagent-#{options.version}.jar"
      options.download = service.deps.jmx_exporter[0].node.fqdn is service.node.fqdn
      options.install_dir ?= "/usr/prometheus/#{options.version}/jmx_exporter"

## Enable JMX Server

      service.deps.hbase_master.options.opts['com.sun.management.jmxremote.authenticate'] ?= 'false'
      service.deps.hbase_master.options.opts['com.sun.management.jmxremote.ssl'] ?= 'false'
      service.deps.hbase_master.options.opts['com.sun.management.jmxremote.port'] ?= '9016'

## Configuration
configure JMX Exporter to scrape HBase RegionServer metrics.

      options.conf_dir ?= "/etc/prometheus-exporter-jmx/conf"
      options.java_home ?= service.deps.java.options.java_home
      options.conf_file ?= "#{options.conf_dir}/hbase_master.yaml"
      # Misc
      options.fqdn ?= service.node.fqdn
      options.hostname = service.node.hostname
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.clean_logs ?= false
      options.port ?= 5562
      options.cluster_name ?= "ryba-env-metal"
      options.config ?= {}
      options.config['startDelaySeconds'] ?= 0
      options.config['ssl'] ?= false
      options.config['hostPort'] ?= "#{service.deps.hbase_master.node.fqdn}:#{service.deps.hbase_master.options.opts['com.sun.management.jmxremote.port']}"
      options.config['lowercaseOutputName'] ?= true
      options.config['rules'] ?= []
      options.config['rules'].push 'pattern': '.*'

## Register Prometheus Scrapper
configure by default two new label, one cluster and the other service
Note: cluster name shoul not contain other character than ([a-zA-Z0-9\-\_]*)

      options.relabel_configs ?= [
          source_labels: ['job']
          regex: "([a-zA-Z0-9\\-\\_]*).([a-zA-Z0-9]*)"
          target_label: "cluster"
          replacement: "$1"
        ,
          source_labels: ['job']
          regex: "([a-zA-Z0-9\\-\\_]*).([a-zA-Z0-9]*)"
          target_label: "service"
          replacement: "$2"
        ,
          source_labels: ['__address__']
          regex: "([a-zA-Z0-9\\-\\_\\.]*):([a-zA-Z0-9]*)"
          target_label: "hostname"
          replacement: "$1"
        ]
      for srv in service.deps.prometheus_monitor
        srv.options.config ?= {}
        srv.options.config['scrape_configs'] ?= []
        scrape_config = null
        # iterate through configuration to find zookeeper's one
        # register current fqdn if not already existing
        for conf in srv.options.config['scrape_configs']
          scrape_config = conf if conf.job_name is "#{options.cluster_name}.hbasemaster"
        exist = scrape_config?
        scrape_config ?=
          job_name: "#{options.cluster_name}.hbasemaster"
          static_configs:
            [
              targets: []
            ]
          relabel_configs: options.relabel_configs
        for static_config in scrape_config.static_configs
          hostPort = "#{service.node.fqdn}:#{options.port}"
          static_config.targets ?= []
          static_config.targets.push hostPort unless static_config.targets.indexOf(hostPort) isnt -1
        srv.options.config['scrape_configs'].push scrape_config unless exist

## Wait

      options.wait ?= {}
      options.wait.jmx ?=
        host: service.node.fqdn
        port: options.port or '5563'

## Dependencies

    {merge} = require 'nikita/lib/misc'

[jmx_exporter]:(https://github.com/prometheus/jmx_exporter)
