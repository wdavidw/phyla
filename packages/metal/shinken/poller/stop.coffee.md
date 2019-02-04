
# Shinken Poller Stop

    module.exports = header: 'Shinken Poller Stop', handler: (options) ->
      @service.stop name: 'shinken-poller'
      
      @docker.stop
        container: 'poller-executor'

## Clean Logs

      @call header: 'Clean Logs', if: options.clean_logs, ->
        @system.execute
          cmd: 'rm /var/log/shinken/pollerd*'
          code_skipped: 1
