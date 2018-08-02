
# Hadoop HDFS JournalNode Check

Check if the JournalNode is running as expected.

    module.exports = header: 'HDFS JN Check', handler: (options) ->

## Wait

Wait for the JournalNodes to listen for RPC and HTTP connections.

      @connection.assert
        header: 'RPC'
        servers: options.wait.rpc.filter (server) -> server.host is options.fqdn
        retry: 3
        sleep: 3000

      @connection.assert
        header: 'HTTP'
        servers: options.wait.http.filter (server) -> server.host is options.fqdn
        retry: 3
        sleep: 3000

## SPNEGO

Test the HTTP server with a JMX request.

      protocol = if options.hdfs_site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      port = options.hdfs_site["dfs.journalnode.#{protocol}-address"].split(':')[1]
      @system.execute
        retry: 3
        sleep: 3000
        header: 'SPNEGO'
        cmd: mkcmd.hdfs options.hdfs_krb5_user, "curl --negotiate -k -u : #{protocol}://#{options.fqdn}:#{port}/jmx?qry=Hadoop:service=JournalNode,name=JournalNodeInfo"
      , (err, obj) ->
        throw err if err
        data = JSON.parse obj.stdout
        throw Error "Invalid Response" unless data.beans[0].name is 'Hadoop:service=JournalNode,name=JournalNodeInfo'

## Dependencies

    mkcmd = require '../../lib/mkcmd'
