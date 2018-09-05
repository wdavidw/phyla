
# JMX Exporter HDFS Journalnode

    module.exports = header: 'JMX Exporter Journalnode Start', handler: ({options}) ->

## Start

      @service.start 'jmx-exporter-hdfs-journalnode'
