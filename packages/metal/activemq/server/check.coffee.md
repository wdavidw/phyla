
# ActiveMQ Server Check

    module.exports =  header: 'ActiveMQ Server Check', handler: ->
      @connection.wait
        host: @config.host
        port: 8161
