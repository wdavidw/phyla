
# Hadoop YARN ResourceManager Status

## Status

Check if the ResourceManager is running. The process ID is located by default
inside "/var/run/hadoop-yarn/yarn-yarn-resourcemanager.pid".

    module.exports = header: 'YARN RM Status', handler: ->
      @service.status
        name: 'hadoop-yarn-resourcemanager'
