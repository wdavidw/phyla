
# Shinken Scheduler Status

    module.exports =  header: 'Shinken Scheduler Status', handler: (options) ->
      @service.status name: 'shinken-scheduler'
