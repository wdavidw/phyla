
# Hadoop ZKFC Status

Check if the ZKFC daemon is running. The process ID is located by default
inside "/var/run/hadoop-hdfs/hdfs/hadoop-hdfs-zkfc.pid".

    module.exports = header: 'HDFS ZKFC Status', handler: ->
      @service.status
        name: 'hadoop-hdfs-zkfc'
