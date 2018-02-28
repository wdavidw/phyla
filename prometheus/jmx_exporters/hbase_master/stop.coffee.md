
# JMX Exporter HDFS Datanode

    module.exports = header: 'JMX Exporter HBase Master Stop', handler: (options) ->

## Start

      @service.stop 'jmx-exporter-hbase-master'
