
# JMX Exporter HDFS Datanode

    module.exports = header: 'JMX Exporter Datanode Start', handler: ({options}) ->

## Start

      @service.start 'jmx-exporter-hdfs-datanode'
