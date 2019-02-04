
# Spark SQL Thrift Server Wait

Wait for the Spark SQL Thrift Server port (HTTP or BINARY).

    module.exports = header: 'Spark SQL Thrift Server Wait', handler: ({options}) ->
      port = if options.hive_site['hive.server2.transport.mode'] is 'http'
      then options.hive_site['hive.server2.thrift.http.port']
      else options.hive_site['hive.server2.thrift.port']

      @connection.wait
        host: options.fqdn
        port: port
