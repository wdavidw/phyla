
# Hadoop HDFS JournalNode Status

Check if the JournalNode Server is running and display the status of the
JournalNode as "STARTED" or "STOPPED".The process ID is located by default
inside "/var/lib/hadoop-hdfs/hdfs/hadoop-hdfs-journalnode.pid".

    module.exports = header: 'HDFS JN Status', handler: ->
      @service.status
        name: 'hadoop-hdfs-journalnode'
