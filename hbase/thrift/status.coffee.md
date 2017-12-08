
# HBase Thrift Status

Check if the Rest is running. The process ID is located by default inside
"/var/run/hbase/hbase-hbase-thrift.pid".

    module.exports = header: 'HBase Thrift Status', handler: ->
      @service.status
        name: 'hbase-thrift'
        if_exists: '/etc/init.d/hbase-thrift'
