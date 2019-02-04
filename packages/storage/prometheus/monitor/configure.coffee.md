
# Prometheus Configure

    module.exports = (service) ->
      options = service.options

## Identities

      # Group
      options.group ?= {}
      options.group = name: options.group if typeof options.group is 'string'
      options.group.name ?= 'prometheus'
      options.group.system ?= true
      # User
      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.name ?= 'prometheus'
      options.user.home ?= "/var/lib/#{options.user.name}"
      options.user.system ?= true
      options.user.comment ?= 'Prometheus User'
      # options.user.groups ?= 'hadoop'
      options.user.gid ?= options.group.name
      options.user.limits ?= {}
      options.user.limits.nofile ?= 64000
      options.user.limits.nproc ?= true

## Packages
November 2017: lucasbak
Ryba does only support prometheus 2.0. If admisitrator want to use older version
the commandline options should be changed (for example -config.file has become --config.file)
in order for systemd to start correctly the process.


      options.version ?= '2.0.0-rc.2'
      options.source ?= "https://github.com/prometheus/prometheus/releases/download/v#{options.version}/prometheus-#{options.version}.linux-amd64.tar.gz"
      # options.repo ?= 'https://packagecloud.io/prometheus-rpm/release/packages/el/7/prometheus-1.8.1-1.el7.centos.x86_64.rpm'
      options.download = service.deps.prometheus_monitor[0].node.fqdn is service.node.fqdn
      options.install_dir ?= "/usr/prometheus/#{options.version}/monitor"
      options.latest_dir ?= '/usr/prometheus/latest/monitor'

## Layout

      options.conf_dir ?= '/etc/prometheus-monitor/conf'
      options.log_dir ?= '/var/log/prometheus'
      options.run_dir ?= '/var/run/prometheus'
      options.iptables ?= !!service.deps.iptables and service.deps.iptables?.options?.action is 'start'

## Configuration

      options.port ?= '9091'
      options.config ?= {}
      options.config['global'] ?= {}
      options.config['global']['scrape_interval'] ?= '15s'
      options.config['global']['evaluation_interval'] ?= '20s'
      options.config['scrape_configs'] ?= []

## Scrappers
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
#       options.config['scrape_configs'] ?= []
#       ## Zookeeper
#       if service.deps.jmx_exporter_zookeeper?.length > 0
#         options.config['scrape_configs'].push
#           job_name: "#{service.deps.jmx_exporter_zookeeper[0].options.cluster_name}.zookeeper"
#           static_configs:
#             [
#               targets: for srv in service.deps.jmx_exporter_zookeeper
#                 "#{srv.node.fqdn}:#{srv.options.port}"
#             ]
#           relabel_configs: options.relabel_configs
#       ## HDFS CLient
#       if service.deps.jmx_exporter_hdfs_dn?.length > 0
#         options.config['scrape_configs'].push
#           job_name: "#{service.deps.jmx_exporter_hdfs_dn[0].options.cluster_name}.datanode"
#           static_configs:
#             [
#               targets: for srv in service.deps.jmx_exporter_hdfs_dn
#                 "#{srv.node.fqdn}:#{srv.options.port}"
#             ]
#           relabel_configs: options.relabel_configs
#       ## HDFS JournalNode
#       if service.deps.jmx_exporter_hdfs_jn?.length > 0
#         options.config['scrape_configs'].push
#           job_name: "#{service.deps.jmx_exporter_hdfs_jn[0].options.cluster_name}.journalnode"
#           static_configs:
#             [
#               targets: for srv in service.deps.jmx_exporter_hdfs_jn
#                 "#{srv.node.fqdn}:#{srv.options.port}"
#             ]
#           relabel_configs: options.relabel_configs
#       ## HDFS NameNode
#       if service.deps.jmx_exporter_hdfs_nn?.length > 0
#         options.config['scrape_configs'].push
#           job_name: "#{service.deps.jmx_exporter_hdfs_nn[0].options.cluster_name}.namenode"
#           static_configs:
#             [
#               targets: for srv in service.deps.jmx_exporter_hdfs_nn
#                 "#{srv.node.fqdn}:#{srv.options.port}"
#             ]
#           relabel_configs: options.relabel_configs

## Storage

      options.storage ?= {}
      options.storage.path ?= "#{options.user.home}/data"

## SSL

      # options.ssl = merge {}, service.deps.ssl?.options, options.ssl
      # options.ssl.enabled ?= !!service.deps.ssl
      # if options.ssl.enabled
      #   throw Error "Required Option: ssl.cert" if  not options.ssl.cert
      #   throw Error "Required Option: ssl.key" if not options.ssl.key
      #   throw Error "Required Option: ssl.cacert" if not options.ssl.cacert
      #   options.config['tls_config'] ?= {}
      #   options.config['tls_config']['ca_file'] ?= "#{options.conf_dir}/cacert.pem"
      #   options.config['tls_config']['cert_file'] ?= "#{options.conf_dir}/cert.pem"
      #   options.config['tls_config']['key_file'] ?= "#{options.conf_dir}/key.pem"
      #   options.config['tls_config']['server_name'] ?= service.node.fqdn
      #   options.config['tls_config']['insecure_skip_verify'] ?= true

## Wait

      options.wait ?= {}
      options.wait.tcp ?= for srv in service.deps.prometheus_monitor
          host: srv.node.fqdn
          port: srv.options.port or options.port or 9091

## Dependencies

    {merge} = require '@nikitajs/core/lib/misc'

## Documentation

[prometheus-storage]:(https://prometheus.io/docs/operating/storage/)
[prometheus-flags]:(http://demo.robustperception.io:9090/flags)
