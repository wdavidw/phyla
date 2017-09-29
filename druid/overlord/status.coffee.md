
# Druid Overlord Status

    module.exports = header: 'Druid Overlord Status', handler: ->
      @service.status
        name: 'druid-overlord'
        if_exists: '/etc/init.d/druid-overlord'
