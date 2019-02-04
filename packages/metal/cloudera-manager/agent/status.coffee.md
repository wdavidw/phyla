
# Cloudera Manager Agent Status

This commands checks the status of Cloudera Manager Agent (STARTED, STOPPED)

    module.exports = header: 'Cloudera Manager Agent Status', handler: ->
      @system.execute
        cmd: 'service cloudera-scm-agent status'
        code_skipped: 3
