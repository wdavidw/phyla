
# JMX Exporter Zookeeper

    module.exports = header: 'JMX Exporter Zookeeper Stop', handler: ({options}) ->

## Start

      @service.stop 'jmx-exporter-zookeeper-server'
