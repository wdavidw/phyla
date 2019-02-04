
# Druid Coordinator Status

    module.exports = header: 'Druid Coordinator Status', handler: ->
      @service.status
        name: 'druid-coordinator'
        if_exists: '/etc/init.d/druid-coordinator'
