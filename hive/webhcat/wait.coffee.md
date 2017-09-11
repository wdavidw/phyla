
# WebHCat Wait

    module.exports = header: 'WebHCat Wait', label_true: 'READY', handler: (options) ->

## HTTP Port

      @connection.wait
        header: 'HTTP'
        servers: options.http

## Dependencies

    mkcmd = require '../../lib/mkcmd'
