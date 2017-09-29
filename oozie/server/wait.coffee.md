
# Oozie Server Wait

Run the command `./bin/ryba status -m ryba/oozie/server` to stop the Oozie
server using Ryba.

    module.exports = header: 'Oozie Server Wait', label_true: 'READY', handler: (options) ->

## HTTP Port

      @connection.wait
        header: 'HTTP'
        servers: options.http

## Dependencies

    url = require 'url'
