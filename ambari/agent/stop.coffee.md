
# Ambari Agent stop

    module.exports =  header: 'Ambari Agent Stop', label_true: 'STOPPED', handler: ->
        @service.stop
          name: 'ambari-agent'
