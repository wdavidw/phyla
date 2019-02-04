
# Kafka Broker Status

    module.exports = header: 'Kafka Broker Status', handler: ->
      @service.status name: 'kafka-broker'
