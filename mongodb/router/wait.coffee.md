
# MongoDB Routing Server Wait

    module.exports = header: 'MongoDB Routing Server Wait', handler: (options) ->
      @connection.wait options.wait.tcp
