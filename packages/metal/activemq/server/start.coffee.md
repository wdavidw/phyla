
# ActiveMQ Server Start

ActiveMQ Server is started through service command.Which is wrapper around 
the docker container.

    module.exports = header: 'ActiveMQ Server Start', handler: ->
      @service.start
        name: 'activemq'
