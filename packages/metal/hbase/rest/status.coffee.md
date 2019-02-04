
# HBase Rest Gateway Status

Check if the Rest is running. The process ID is located by default inside
"/var/run/hbase/hbase-hbase-rest.pid".

    module.exports = header: 'HBase Rest Status', handler: ->
      @service.status
        name: 'hbase-rest'
