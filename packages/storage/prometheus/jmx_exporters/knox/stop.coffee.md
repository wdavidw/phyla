
# JMX Exporter Knox

    module.exports = header: 'JMX Exporter Knox Stop', handler: ({options}) ->

## Start

      @service.stop 'jmx-exporter-knox'
