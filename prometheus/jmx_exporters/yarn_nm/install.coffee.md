
# JMX Exporter Yarn NodeManager Install

    module.exports = header: 'JMX Exporter NodeManager Install', handler: ({options}) ->

## Registry

      @registry.register ['jmx', 'exporter'], 'ryba/prometheus/actions/jmx_exporter'

## Identities

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Systemd

      @call
        if_os: name: ['redhat','centos'], version: '7'
      , ->
        java_opts = options.opts.base
        java_opts += " -D#{k}=#{v}" for k, v of options.opts.java_properties
        java_opts += " #{k}#{v}" for k, v of options.opts.jvm
        options.java_opts = java_opts
        @service.init
          header: 'Systemd Script'
          target: '/usr/lib/systemd/system/jmx-exporter-yarn-nodemanager.service'
          source: "#{__dirname}/../../resources/prometheus-jmx-exporter-systemd.j2"
          local: true
          context: options
          mode: 0o0640

## Layout

      @jmx.exporter
        title: 'NM JMX'
        jar_source: options.jar_source
        jar_target: "#{options.install_dir}/jmx_exporter.jar"
        config: options.config
        target: options.conf_file
        iptables: options.iptables
        port: options.port
        user: options.user
        group: options.group
