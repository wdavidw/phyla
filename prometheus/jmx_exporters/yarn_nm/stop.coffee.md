
# JMX Exporter Yarn NodeManager

    module.exports = header: 'JMX Exporter Yarn NodeManager Stop', handler: (options) ->

## Start

      @service.stop 'jmx-exporter-yarn-nodemanager'
