
# OpenTSDB Stop

Stop the OpenTSDB service.

    module.exports = header: 'OpenTSDB Stop', handler: (options) ->
      @service.stop
        name: 'opentsdb'
        if_exists: '/etc/init.d/opentsdb'

## Stop Clean Logs

      @call header: 'Stop Clean Logs', ->
        return unless options.clean_logs
        @system.execute
          cmd: 'rm /var/log/opentsdb/*'
          code_skipped: 1
