
# Hadoop YARN Timeline Server Start

## Status

Check if the Timeline Server is running. The process ID is located by default
inside "/var/run/hadoop-yarn/yarn-yarn-timelineserver.pid" (TODO, check the pid file!).

    module.exports = header: 'YARN ATS Status', handler: ->
      @service.status
        name: 'hadoop-yarn-timelineserver'
