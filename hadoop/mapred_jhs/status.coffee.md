
# MapReduce JobHistoryServer Status

Check if the Job History Server is running. The process ID is located by default
inside "/var/run/hadoop-mapreduce/".

    module.exports = header: 'MapReduce JHS Status', handler: ->
      @service.status
        name: 'hadoop-mapreduce-historyserver'
