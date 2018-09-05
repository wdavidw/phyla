
# JMX Exporter HDFS Datanode

    module.exports = header: 'JMX Exporter RegionServer Stop', handler: ({options}) ->

## Start

      @service.stop 'jmx-exporter-hbase-regionserver'
