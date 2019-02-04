
# Cloudera Manager Server stop

    module.exports = header: 'Cloudera Manager Server Stop', handler: ->
      @service.stop
        name: 'cloudera-scm-server'
