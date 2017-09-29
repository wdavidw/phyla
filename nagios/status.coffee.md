
# Nagios Status

    module.exports = name: 'Nagios Status', handler: ->
      @service.status
        name: 'nagios'
        code_stopped: 1
