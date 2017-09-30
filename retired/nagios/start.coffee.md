
# Nagios Start

    module.exports = header: 'Nagios Start', handler: ->
      @service.start
        name: 'nagios'
        code_stopped: 1
