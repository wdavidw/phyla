
# Hadoop HDFS SecondaryNameNode 

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
    configure:
      'ryba/hadoop/hdfs_snn/configure'
    commands:
      'install': [
        'ryba/hadoop/hdfs_snn/install'
        'ryba/hadoop/hdfs_snn/start'
      ]
      'start':
        'ryba/hadoop/hdfs_snn/start'
      'status':
        'ryba/hadoop/hdfs_snn/status'
      'stop':
        'ryba/hadoop/hdfs_snn/stop'
