
# JMX Exporter NameNode Check

    module.exports = header: 'JMX Exporter Namenode Install', handler: ({options}) ->

## Registry

      @registry.register ['jmx', 'exporter'], 'ryba/prometheus/actions/jmx_exporter'

## Identities

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user


      @call
        if_os: name: ['redhat','centos'], version: '6'
      , ->
        java_opts = options.opts.base
        java_opts += " -D#{k}=#{v}" for k, v of options.opts.java_properties
        java_opts += " #{k}#{v}" for k, v of options.opts.jvm
        options.java_opts = java_opts
        @service.init
          header: 'Initd Script'
          target: '/etc/init.d/jmx-exporter-hdfs-namenode'
          source: "#{__dirname}/../../resources/prometheus-jmx-exporter-initd.j2"
          local: true
          context: options
          mode: 0o0755

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
          target: '/usr/lib/systemd/system/jmx-exporter-hdfs-namenode.service'
          source: "#{__dirname}/../../resources/prometheus-jmx-exporter-systemd.j2"
          local: true
          context: options
          mode: 0o0640

## JMX Exporter

      @jmx.exporter
        title: 'NN JMX'
        jar_source: options.jar_source
        jar_target: "#{options.install_dir}/jmx_exporter.jar"
        config: options.config
        target: options.conf_file
        iptables: options.iptables
        port: options.port
        user: options.user
        group: options.group
