
# Shinken Scheduler Stop

    module.exports = header: 'Shinken Scheduler Stop', handler: (options) ->
      @service.stop name: 'shinken-scheduler'

## Clean Logs

      @call header: 'Clean Logs', if: options.clean_logs, ->
        @system.execute
          cmd: 'rm /var/log/shinken/schedulerd*'
          code_skipped: 1
