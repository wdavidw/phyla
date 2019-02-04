
# Hadoop HDFS JournalNode

This module configure the JournalNode following the 
[HDFS High Availability Using the Quorum Journal Manager](https://hadoop.apache.org/docs/r2.3.0/hadoop-yarn/hadoop-yarn-site/HDFSHighAvailabilityWithQJM.html) official 
recommandations.

In order for the Standby node to keep its state synchronized with the Active 
node, both nodes communicate with a group of separate daemons called 
"JournalNodes" (JNs). When any namespace modification is performed by the Active 
node, it durably logs a record of the modification to a majority of these JNs. 
The Standby node is capable of reading the edits from the JNs, and is constantly 
watching them for changes to the edit log.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        hdfs_jn: module: '@rybajs/metal/hadoop/hdfs_jn'
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
        metrics: module: '@rybajs/metal/metrics', local: true
      configure:
        '@rybajs/metal/hadoop/hdfs_jn/configure'
      commands:
        # 'backup':
        #   '@rybajs/metal/hadoop/hdfs_jn_backup'
        'check':
          '@rybajs/metal/hadoop/hdfs_jn/check'
        'install': [
          '@rybajs/metal/hadoop/hdfs_jn/install'
          '@rybajs/metal/hadoop/hdfs_jn/start'
          '@rybajs/metal/hadoop/hdfs_jn/check'
        ]
        'start':
          '@rybajs/metal/hadoop/hdfs_jn/start'
        'status':
          '@rybajs/metal/hadoop/hdfs_jn/status'
        'stop':
          '@rybajs/metal/hadoop/hdfs_jn/stop'


[qjm]: http://hadoop.apache.org/docs/r2.3.0/hadoop-yarn/hadoop-yarn-site/HDFSHighAvailabilityWithQJM.html#Architecture
