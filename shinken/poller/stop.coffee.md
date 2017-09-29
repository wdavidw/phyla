
# Shinken Poller Stop

    module.exports = header: 'Shinken Poller Stop', handler: ->
      @service.stop name: 'shinken-poller'

## Clean Logs

      @call header: 'Clean Logs', if: @config.ryba.clean_logs, ->
        @system.execute
          cmd: 'rm /var/log/shinken/pollerd*'
          code_skipped: 1
