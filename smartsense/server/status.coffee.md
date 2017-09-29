
# HST Server Status

    module.exports = header: 'HST Server Status', label_true: 'STARTED', handler: (options) ->
      @service.status
        name: 'hst-server'
