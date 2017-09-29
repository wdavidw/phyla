
# OpenTSDB Wait

Wait for the HTTP port.

    module.exports = header: 'OpenTSDB Wait', handler: ->
      options = {}
      options.servers =
        host: @config.host
        port: @config.ryba.opentsdb.config['tsd.network.port']

## HTTP Port

      @connection.wait
        header: 'HTTP'
      , options
