
# JMX Exporter HDFS Journalnode

    module.exports = header: 'JMX Exporter Journalnode Stop', handler: (options) ->

## Start

      @service.stop 'jmx-exporter-hdfs-journalnode'
