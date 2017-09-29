## Check Hst Agent

Check the HST Agent host registration status

    module.exports = header: 'HST Agent Check', label_true: 'CHECKED', handler: (options) ->
      @system.execute
        cmd: 'hst agent-status | grep registered'
