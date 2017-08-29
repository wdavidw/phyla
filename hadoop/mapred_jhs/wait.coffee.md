
# MapReduce JobHistoryServer Wait

    module.exports = header: 'MapReduce JHS Wait', label_true: 'READY', handler: (options) ->

## TCP

      @connection.wait
        header: 'TCP'
        servers: options.tcp

## HTTP

      @connection.wait
        header: 'HTTP'
        servers: options.webapp
