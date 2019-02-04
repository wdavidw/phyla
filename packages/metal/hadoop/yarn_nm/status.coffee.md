
# YARN NodeManager Status

Check if the Yarn NodeManager server is running. The process ID is located by
default inside "/var/run/hadoop-yarn/yarn-yarn-nodemanager.pid".

    module.exports = header: 'YARN NM Status', handler: ->
      @service.status
        name: 'hadoop-yarn-nodemanager'
