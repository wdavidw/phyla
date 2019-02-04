
# Falcon Server Check

    module.exports = header: 'Falcon Server Check', handler: ->
      {falcon} = @config.ryba
      {hostname, port} = url.parse falcon.runtime['prism.falcon.local.endpoint']

## Wait

Wait for the Falcon server to become available.

      @call once: true, '@rybajs/metal/falcon/server/wait'

## Connection

      @connection.assert
        host: hostname
        port: port

## Dependencies

    url = require 'url'
