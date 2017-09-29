
# Shinken Scheduler Start

    module.exports = header: 'Shinken Scheduler Start', handler: ->
      @service.start name: 'shinken-scheduler'
