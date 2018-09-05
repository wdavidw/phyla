
# JMX Exporter HDFS Datanode

    module.exports = header: 'JMX Exporter HBase Master Start', handler: ({options}) ->

## Start

      @service.start 'jmx-exporter-hbase-master'
