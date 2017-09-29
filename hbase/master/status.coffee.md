
# HBase Master Status

Check if the HBase Master is running. The process ID is located by default
inside "/var/run/hbase/hbase-hbase-master.pid".

    module.exports = header: 'HBase Master Status', handler: ->
      @service.status
        name: 'hbase-master'
