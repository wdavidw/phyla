
# Hadoop HDFS DataNode Wait

    module.exports = header: 'HDFS DN Wait', handler: (options) ->

## Wait for all datanode IPC Ports

Port is defined in the "dfs.datanode.address" property of hdfs-site. The default
value is 50020.

      @connection.wait
        header: 'IPC'
        servers: options.ipc

## Wait for all datanode HTTP Ports

Port is defined in the "dfs.datanode.https.address" property of hdfs-site. The default
value is 50475.

      @connection.wait
        header: 'HTTP'
        servers: options.http
