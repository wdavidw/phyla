
# Shinken Receiver Stop

    module.exports = header: 'Shinken Receiver Stop', handler: (options) ->
      @service.stop name: 'shinken-receiver'

## Clean Logs

      @call header: 'Clean Logs', if: options.clean_logs, ->
        @system.execute
          cmd: 'rm /var/log/shinken/receiverd*'
          code_skipped: 1
