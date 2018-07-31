
# JMX Exporter HDFS Datanode

    module.exports = header: 'JMX Exporter Rest Stop', handler: (options) ->

## Start

      @service.stop 'jmx-exporter-hbase-rest'
