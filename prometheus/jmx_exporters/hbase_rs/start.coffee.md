
# JMX Exporter HDFS Datanode

    module.exports = header: 'JMX Exporter RegionServer Start', handler: (options) ->

## Start

      @service.start 'jmx-exporter-hbase-regionserver'
