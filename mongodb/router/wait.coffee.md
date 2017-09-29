
# MongoDB Routing Server Wait

    module.exports = header: 'MongoDB Routing Server Wait', label_true: 'READY', handler: (options) ->
      @connection.wait options.wait.tcp
