
# JMX Exporter Yarn ResourceManager

    module.exports = header: 'JMX Exporter Yarn ResourceManager Stop', handler: ({options}) ->

## Start

      @service.stop 'jmx-exporter-yarn-resourcemanager'
