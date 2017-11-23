
# JMX Exporter HDFS Datanode

    module.exports = header: 'Collectd Exporter Start', handler: (options) ->

## Start

      @service.start 'prometheus-collectd-exporter'
