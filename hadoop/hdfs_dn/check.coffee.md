
# Hadoop HDFS DataNode Check

Check the DataNode by uploading a file using the HDFS client and the HTTP REST
interface.

Run the command `./bin/ryba check -m ryba/hadoop/hdfs_dn` to check all the
DataNodes.


    module.exports = header: 'HDFS DN Check', handler: (options) ->

## Wait for all datanode TCP Ports

Port is defined in the "dfs.datanode.address" property of hdfs-site. The default
value is 50020.

      @connection.assert
        header: 'TCP'
        servers: options.wait.tcp_local
        retry: 10
        sleep: 5000

## Wait for all datanode IPC Ports

Port is defined in the "dfs.datanode.ipc.address" property of hdfs-site. The
default value is 50020. IPC, for InterProcess Communication, is a fast and easy 
RPC mechanism. It is used as the internal procedure call mechanism for all 
Hadoop and Nutch.

      @connection.assert
        header: 'IPC'
        servers: options.wait.ipc_local
        retry: 10
        sleep: 5000

## Wait for all datanode HTTP Ports

Port is defined in the "dfs.datanode.{http|https}.address" property of hdfs-site. The default
value is 50475.

      @connection.assert
        header: 'HTTP'
        servers: options.wait.http_local
        retry: 3
        sleep: 3000

## Check Disk Capacity

      protocol = if options.hdfs_site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      port = options.hdfs_site["dfs.datanode.#{protocol}.address"].split(':')[1]
      @system.execute
        header: 'SPNEGO'
        retry: 3
        cmd: mkcmd.hdfs options.hdfs_krb5_user, "curl --negotiate -k -u : #{protocol}://#{options.fqdn}:#{port}/jmx?qry=Hadoop:service=DataNode,name=DataNodeInfo"
      , (err, obj) ->
        throw err if err
        throw Error "Invalid Response" unless JSON.parse(obj.stdout)?.beans[0]?.name is 'Hadoop:service=DataNode,name=DataNodeInfo'
      # @system.execute
      #   cmd: mkcmd.hdfs options.hdfs_krb5_user, "curl --negotiate -k -u : #{protocol}://#{options.fqdn}:#{port}/jmx?qry=Hadoop:service=DataNode,name=FSDatasetState-*"
      # , (err, executed, stdout) ->
      #   throw err if err
      #   data = JSON.parse stdout
      #   throw Error "Invalid Response" unless /^Hadoop:service=DataNode,name=FSDatasetState-.*/.test data?.beans[0]?.name
      #   remaining = data.beans[0].Remaining
      #   total = data.beans[0].Capacity
      #   @log "Disk remaining: #{Math.round remaining}"
      #   @log "Disk total: #{Math.round total}"
      #   percent = (total - remaining)/total * 100;
      #   @log "WARNING: #{Math.round percent}" if percent > 90
      #  .next next

      @system.execute
        header: 'Native'
        trap: true
        cmd: """
        nativelist=`hadoop checknative`
        echo $nativelist | egrep 'hadoop:\\s+true'
        echo $nativelist | egrep 'zlib:\\s+true'
        echo $nativelist | egrep 'snappy:\\s+true'
        echo $nativelist | egrep 'lz4:\\s+true'
        echo $nativelist | egrep 'bzip2:\\s+true'
        echo $nativelist | egrep 'openssl:\\s+true'
        """

## Dependencies

    mkcmd = require '../../lib/mkcmd'
