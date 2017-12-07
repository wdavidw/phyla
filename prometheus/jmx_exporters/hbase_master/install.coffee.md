
# JMX Exporter HBase Master Install

    module.exports = header: 'JMX Exporter HBase Master Install', handler: (options) ->

## Registry

      @registry.register ['jmx', 'exporter'], 'ryba/prometheus/actions/jmx_exporter'

## Identities

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Systemd

      @call
        if_os: name: ['redhat','centos'], version: '7'
      , ->
        @service.init
          header: 'Systemd Script'
          target: '/usr/lib/systemd/system/jmx-exporter-hbase-master.service'
          source: "#{__dirname}/../../resources/prometheus-jmx-exporter-systemd.j2"
          local: true
          context: options
          mode: 0o0640

## Layout

      @jmx.exporter
        title: 'HBM JMX'
        jar_source: options.jar_source
        jar_target: "#{options.install_dir}/jmx_exporter.jar"
        config: options.config
        target: options.conf_file
        iptables: options.iptables
        port: options.port
        user: options.user
        group: options.group
