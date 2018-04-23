
# JMX Exporter Datanode Install

    module.exports = header: 'JMX Exporter Datanode Install', handler: (options) ->

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
          target: '/usr/lib/systemd/system/jmx-exporter-hdfs-datanode.service'
          source: "#{__dirname}/../../resources/prometheus-jmx-exporter-systemd.j2"
          local: true
          context: options
          mode: 0o0640

## Layout

      @jmx.exporter
        title: 'DN JMX'
        jar_source: options.jar_source
        jar_target: "#{options.install_dir}/jmx_exporter.jar"
        config: options.config
        target: options.conf_file
        iptables: options.iptables
        port: options.port
        user: options.user
        group: options.group

## SSL 

      @java.keystore_add
        header: 'Truststore'
        keystore: options.opts.java_properties['javax.net.ssl.trustStore']
        storepass: options.opts.java_properties['javax.net.ssl.trustStorePassword']
        caname: "hadoop_root_ca"
        cacert: "#{options.ssl.cacert.source}"
        local: "#{options.ssl.cacert.local}"
        uid: options.user.name

