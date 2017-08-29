
# Hadoop HDFS JournalNode Check

Check if the JournalNode is running as expected.

    module.exports = header: 'HDFS JN Check', label_true: 'CHECKED', handler: (options) ->

Wait for the JournalNodes.

      @connection.assert
        header: 'RPC'
        servers: options.wait.rpc
        retry: 3
        sleep: 3000

Test the HTTP server with a JMX request.

      protocol = if options.hdfs_site['dfs.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      port = options.hdfs_site["dfs.journalnode.#{protocol}-address"].split(':')[1]
      @system.execute
        header: 'SPNEGO'
        cmd: mkcmd.hdfs @, "curl --negotiate -k -u : #{protocol}://#{@config.host}:#{port}/jmx?qry=Hadoop:service=JournalNode,name=JournalNodeInfo"
      , (err, executed, stdout) ->
        throw err if err
        data = JSON.parse stdout
        throw Error "Invalid Response" unless data.beans[0].name is 'Hadoop:service=JournalNode,name=JournalNodeInfo'

## Dependencies

    mkcmd = require '../../lib/mkcmd'
