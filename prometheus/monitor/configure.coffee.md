
# Prometheus Configure

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/prometheus/monitor', ['ryba', 'prometheus', 'monitor'], require('nikita/lib/misc').merge require('.').use,
        iptables: key: ['iptables']
        ssl: key: ['ssl']
        prometheus_monitor: key: ['ryba', 'prometheus', 'monitor']
        jmx_exporter_zookeeper: key: ['ryba', 'prometheus', 'jmx_exporters', 'zookeeper']
      @config.ryba.prometheus ?= {}
      options = @config.ryba.prometheus.monitor = service.options

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
      options.user.groups ?= 'hadoop'
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
      options.download = service.use.prometheus_monitor[0].node.fqdn is service.node.fqdn
      options.install_dir ?= "/usr/promotheus/#{options.version}/monitor"
      options.latest_dir ?= '/usr/promotheus/latest/monitor'

## Layout

      options.conf_dir ?= '/etc/prometheus-monitor/conf'
      options.log_dir ?= '/var/log/prometheus'
      options.run_dir ?= '/var/run/prometheus'

## Configuration

      options.port ?= '9091'
      options.config ?= {}
      options.config['global'] ?= {}
      options.config['global']['scrape_interval'] ?= '15s'
      options.config['global']['evaluation_interval'] ?= '20s'

## Scrappers
      
      options.config['scrape_configs'] ?= []
      if service.use.jmx_exporter_zookeeper.length > 0
        options.config['scrape_configs'].push
          job_name: 'zookeeper'
          static_configs:
            [
              targets: for srv in service.use.jmx_exporter_zookeeper
                "#{srv.node.fqdn}:#{srv.options.port}"
            ]

## Storage

      options.storage ?= {}
      options.storage.path ?= "#{options.user.home}/data"

## SSL

      # options.ssl = merge {}, service.use.ssl?.options, options.ssl
      # options.ssl.enabled ?= !!service.use.ssl
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
      options.wait.tcp ?= for srv in service.use.prometheus_monitor
          host: srv.node.fqdn
          port: srv.options.port or options.port or 9091

## Dependencies

    migration = require 'masson/lib/migration'
    {merge} = require 'nikita/lib/misc'

## Documentation

[prometheus-storage]:(https://prometheus.io/docs/operating/storage/)
[prometheus-flags]:(http://demo.robustperception.io:9090/flags)
