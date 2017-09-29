
# Spark History Server Status

    module.exports = header: 'Spark History Server Status', handler: ->
      @service.status
        name: 'spark-history-server'
        if_exist: '/etc/init.d/spark-history-server'
