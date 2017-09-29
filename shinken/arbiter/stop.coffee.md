
# Shinken Arbiter Stop

    module.exports = header: 'Shinken Arbiter Stop', handler: ->
      @service.stop name: 'shinken-arbiter'

## Clean Logs

      @call header: 'Clean Logs', if: @config.ryba.clean_logs, handler: ->
        @system.execute
          cmd: 'rm /var/log/shinken/arbiterd*'
          code_skipped: 1
