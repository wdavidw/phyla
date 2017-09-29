
# Shinken Scheduler Stop

    module.exports = header: 'Shinken Scheduler Stop', handler: ->
      @service.stop name: 'shinken-scheduler'

## Clean Logs

      @call header: 'Clean Logs', if: @config.ryba.clean_logs, ->
        @system.execute
          cmd: 'rm /var/log/shinken/schedulerd*'
          code_skipped: 1
