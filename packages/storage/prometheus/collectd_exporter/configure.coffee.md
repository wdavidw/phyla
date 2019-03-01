
# Configure Collectd Exporter

    module.exports = (service) ->
      options = service.options

## Identities

      # Group
      options.group ?= mixme service.deps.prometheus_monitor[0].options.group, options.group
      options.user ?= mixme service.deps.prometheus_monitor[0].options.user, options.user

## Package
    
      options.version ?= '0.3.1'
      #standalone server
      options.source ?= "https://github.com/prometheus/collectd_exporter/releases/download/#{options.version}/collectd_exporter-#{options.version}.linux-amd64.tar.gz"
      # java agent
      # options.agent_source ?= "https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/#{options.version}/jmx_prometheus_javaagent-#{options.version}.jar"
      options.download = service.deps.collectd_exporter[0].node.fqdn is service.node.fqdn
      options.install_dir ?= "/usr/prometheus/collectd_exporter/#{options.version}"

## Configuration
Configure the collectd_exporter. There is no documentation about how to configure.
only start option such as listen address.
The listen_port listend to collectd post metrics, while port is the target where
prometheus will scrape metrics on collectd_exporter.

      options.listen_port ?= 9020
      options.port ?= 9103
      # Misc
      options.fqdn ?= service.node.fqdn
      options.hostname = service.node.hostname
      options.iptables ?= service.deps.iptables and service.deps.iptables.options.action is 'start'
      options.clean_logs ?= false
      options.port ?= 5557
      options.cluster_name ?= "ryba-env-metal"

## Enable Local Collectd network Plugin
Collectd can use network (binary protocol) or http to send metrics to collect_exporter.
By default we only use network plugin.

Enables also [df plugin](https://collectd.org/wiki/index.php/Plugin:DF) to gather
filesystem infos.

      service.deps.collectd.options.plugins ?= {}
      service.deps.collectd.options.plugins['collectd-exporter'] ?=
        type: 'write_http'
        url: "http://#{service.node.fqdn}:#{options.port}/collectd-post"
        node: 'collectd_exporter'
        port: 9103
      
      service.deps.collectd.options.plugins['collectd-df'] ?=
        type: 'df'
     # type: 'network'
        # host: service.node.fqdn
        # port: 9103

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
          scrape_config = conf if conf.job_name is "#{options.cluster_name}.collectd"
        exist = scrape_config?
        scrape_config ?=
          job_name: "#{options.cluster_name}.collectd"
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
      options.wait.tcp ?=
        host: service.node.fqdn
        port: options.port or 9103

## Dependencies

    mixme = require 'mixme'

[example]:(https://github.com/prometheus/jmx_exporter/blob/master/example_configs/zookeeper.yaml)
[collectd_exporter]:(https://github.com/prometheus/collectd_exporter)
