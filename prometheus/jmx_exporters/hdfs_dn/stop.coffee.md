
# JMX Exporter HDFS Datanode

    module.exports = header: 'JMX Exporter Datanode Stop', handler: ({options}) ->

## Start

      @service.stop 'jmx-exporter-hdfs-datanode'
