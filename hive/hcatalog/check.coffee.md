
# Hive HCatalog Check

    module.exports =  header: 'Hive HCatalog Check', label_true: 'CHECKED', handler: (options) ->

## Asset Connection

The Hive metastore listener port, default to "9083".

      @connection.assert
        header: 'RPC'
        servers: options.wait.rpc.filter (server) -> server.host is options.fqdn
        retry: 3
        sleep: 3000

## Check Database

Check if Hive can authenticate and run a basic query to the database.

      @call header: 'Database', ->
        cmd = switch options.db.engine
          when 'mariadb', 'mysql' then 'SELECT * FROM VERSION'
          when 'postgresql' then '\\dt'
        @system.execute
          cmd: db.cmd options.db, admin_username: null, cmd

## Check Port

Check if the Hive HCatalog (Metastore) server is listening.

      # migration: wdavidw 170911, this is the same as the connection.assert call just above
      # @connection.assert
      #   header: 'Port'
      #   server: options.hive_site['hive.metastore.uris']
      #     .split(',')
      #     .map (uri) ->
      #       {fqdn, port} = url.parse uri
      #       host: fqdn, port: port
      #     .filter (server) ->
      #       server.fqdn is options.fqdn

# Module Dependencies

    url = require 'url'
    db = require 'nikita/lib/misc/db'
