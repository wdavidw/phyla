
# Cloudera Manager Status Status

This commands checks the status of Cloudera Manager Server (STARTED, STOPPED)

    module.exports = header: 'Cloudera Manager Status', handler: ->
      @system.execute
        cmd: 'service cloudera-scm-status status'
        code_skipped: 3
