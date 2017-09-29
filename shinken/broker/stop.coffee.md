
# Shinken Broker Stop

    module.exports = header: 'Shinken Broker Stop', handler: ->
      @service.stop name: 'shinken-broker'

## Clean Logs

      @call header: 'Clean Logs', if: @config.ryba.clean_logs, ->
        @system.execute
          cmd: 'rm /var/log/shinken/brokerd*'
          code_skipped: 1
