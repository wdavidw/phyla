
# Hadoop HDFS SecondaryNameNode 

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
    configure:
      '@rybajs/metal/hadoop/hdfs_snn/configure'
    commands:
      'install': [
        '@rybajs/metal/hadoop/hdfs_snn/install'
        '@rybajs/metal/hadoop/hdfs_snn/start'
      ]
      'start':
        '@rybajs/metal/hadoop/hdfs_snn/start'
      'status':
        '@rybajs/metal/hadoop/hdfs_snn/status'
      'stop':
        '@rybajs/metal/hadoop/hdfs_snn/stop'
