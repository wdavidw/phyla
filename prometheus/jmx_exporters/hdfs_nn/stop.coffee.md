
# JMX Exporter HDFS Namenode

    module.exports = header: 'JMX Exporter Namenode Stop', handler: ({options}) ->

## Start

      @service.stop 'jmx-exporter-hdfs-namenode'
