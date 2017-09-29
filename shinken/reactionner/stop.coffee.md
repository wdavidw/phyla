
# Shinken Reactionner Stop

    module.exports = header: 'Shinken Reactionner Stop', handler: ->
      @service.stop name: 'shinken-reactionner'

## Clean Logs

      @call header: 'Clean Logs', if: @config.ryba.clean_logs, ->
        @system.execute
          cmd: 'rm /var/log/shinken/reactionnerd*'
          code_skipped: 1
