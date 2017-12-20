
# Shinken Broker Stop

    module.exports = header: 'Shinken Broker Stop', handler: (options) ->
      @service.stop name: 'shinken-broker'

## Clean Logs

      @call header: 'Clean Logs', if: options.clean_logs, ->
        @system.execute
          cmd: 'rm /var/log/shinken/brokerd*'
          code_skipped: 1
