
# JMX Exporter HDFS Datanode

    module.exports = header: 'JMX Exporter Rest Start', handler: ({options}) ->

## Start

      @service.start 'jmx-exporter-hbase-rest'
