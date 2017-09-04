
## Hbase Thrift server check

    module.exports = header: 'HBase Thrift Check', label_true: 'CHECKED', handler: (options) ->

## Assert HTTP Port

      @connection.assert
        header: 'HTTP'
        servers: options.wait.http.filter (server) -> server.host is options.fqdn

## Assert HTTP Info Port

      @connection.assert
        header: 'HTTP Info'
        servers: options.wait.http_info.filter (server) -> server.host is options.fqdn

## Check Shell

      @system.execute
        header: 'TCP'
        cmd: "echo > /dev/tcp/#{options.fqdn}/#{options.hbase_site['hbase.thrift.port']}"

# TODO: Novembre 2015 check Thrift  server by interacting with hbase

For now Hbase provided example does not work with SSL enabled Hbase Thrift Server.
