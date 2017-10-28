
# Prometheus Install

    module.exports = header: 'Prometheus JMX Exporter Zookeeper Install', handler: (options) ->

## Registry

      @registry.register ['jmx', 'exporter'], 'ryba/prometheus/actions/jmx_exporter'

## JMX Exporter

      @jmx.exporter
        title: 'Zookeeper'
        agent_source: options.agent_source
        agent_target: "#{options.install_dir}/jmx_exporter_agent.jar"
        config: options.config
        target: "#{options.conf_dir}/zookeeper.yaml"
        iptables: options.iptables
        port: options.port
        user: options.user
        group: options.group
