
# Prometheus Install

    module.exports = header: 'JMX Exporter Zookeeper Install', handler: ({options}) ->
      
## Registry

      @registry.register ['jmx', 'exporter'], 'ryba/prometheus/actions/jmx_exporter'

## Systemd

      @call
        if_os: name: ['redhat','centos'], version: '7'
      , ->
        @service.init
          header: 'Systemd Script'
          target: '/usr/lib/systemd/system/jmx-exporter-zookeeper-server.service'
          source: "#{__dirname}/../../resources/prometheus-jmx-exporter-systemd.j2"
          local: true
          context: options
          mode: 0o0640

## JMX Exporter

      @jmx.exporter
        title: 'Zookeeper'
        jar_source: options.jar_source
        jar_target: "#{options.install_dir}/jmx_exporter.jar"
        config: options.config
        target: options.conf_file
        iptables: options.iptables
        port: options.port
        user: options.user
        group: options.group
