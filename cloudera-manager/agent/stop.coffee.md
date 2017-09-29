
# Cloudera Manager Agent stop

    module.exports = header: 'Cloudera Manager Agent Stop', handler: ->
      @service.stop
        name: 'cloudera-scm-agent'
