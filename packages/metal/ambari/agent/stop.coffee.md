
# Ambari Agent stop

    module.exports =  header: 'Ambari Agent Stop', handler: ->
        @service.stop
          name: 'ambari-agent'
