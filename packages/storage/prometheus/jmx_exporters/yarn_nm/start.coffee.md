
# JMX Exporter Yarn NodeManager

    module.exports = header: 'JMX Exporter Yarn NodeManager Start', handler: ({options}) ->

## Start

      @service.start 'jmx-exporter-yarn-nodemanager'
