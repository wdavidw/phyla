
# Hadoop HDFS NameNode Status

Check if the HDFS NameNode server is running. The process ID is located by default
inside "/var/run/hadoop-hdfs/hdfs/hadoop-hdfs-namenode.pid".

    module.exports = header: 'HDFS NN Status', handler: ->
      @service.status
        name: 'hadoop-hdfs-namenode'
