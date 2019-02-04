
# Hadoop YARN Timeline Server Check

Check the Timeline Server.

    module.exports = header: 'YARN TR HBase Embedded Check', handler: ({options}) ->

## Assert

Ensure The the server to be started.

      @connection.assert
        header: 'Webapp'
        servers: options.master_rpc
        retry: 3
        sleep: 3000

      @connection.assert
        header: 'Webapp'
        servers: options.regionserver_rpc
        retry: 3
        sleep: 3000

      @connection.assert
        header: 'Webapp'
        servers: options.master_http
        retry: 3
        sleep: 3000

      @connection.assert
        header: 'Webapp'
        servers: options.regionserver_http
        retry: 3
        sleep: 3000

## Check HBase shell

      @system.execute
        header: 'HBase Shell List'
        cmd: mkcmd.hbase options.yarn_ats_user, """
        echo '[DEBUG] Namespace level'
        echo 'list' | hbase --config #{options.conf_dir} shell 2>/dev/null | egrep '[0-9]+ row'
        """
        trap: true


# Dependencies

    mkcmd = require '../../lib/mkcmd'
