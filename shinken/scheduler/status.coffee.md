
# Shinken Scheduler Status

    module.exports =  header: 'Shinken Scheduler Status', handler: ->
      @service.status name: 'shinken-scheduler'
