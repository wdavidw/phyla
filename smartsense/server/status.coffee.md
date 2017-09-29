
# HST Server Status

    module.exports = header: 'HST Server Status', label_true: 'STARTED', label_false: 'STOPPED', handler: (options) ->
      @service.status
        name: 'hst-server'
