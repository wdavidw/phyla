
# JMX Exporter HDFS Namenode

    module.exports = header: 'JMX Exporter Namenode Start', handler: ({options}) ->

## Start

      @service.start 'jmx-exporter-hdfs-namenode'
