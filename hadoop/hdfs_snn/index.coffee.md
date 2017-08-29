
# Hadoop HDFS SecondaryNameNode 

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, required: true
    configure:
      'ryba/hadoop/hdfs_snn/configure'
    commands:
      'install': ->
        options = @config.ryba.hdfs.snn
        @call 'ryba/hadoop/hdfs_snn/install', options
        @call 'ryba/hadoop/hdfs_snn/start', options
      'start':
        'ryba/hadoop/hdfs_snn/start'
      'status':
        'ryba/hadoop/hdfs_snn/status'
      'stop': ->
        options = @config.ryba.hdfs.snn
        @call 'ryba/hadoop/hdfs_snn/stop', options
