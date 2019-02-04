
# Shinken Scheduler Start

    module.exports = header: 'Shinken Scheduler Start', handler: (options) ->
      @service.start name: 'shinken-scheduler'
