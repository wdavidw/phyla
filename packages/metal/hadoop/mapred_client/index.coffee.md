
# MapReduce Client

MapReduce is the key algorithm that the Hadoop MapReduce engine uses to distribute work around a cluster.
The key aspect of the MapReduce algorithm is that if every Map and Reduce is independent of all other ongoing Maps and Reduces,
then the operation can be run in parallel on different keys and lists of data. On a large cluster of machines, you can go one step further, and run the Map operations on servers where the data lives.
Rather than copy the data over the network to the program, you push out the program to the machines.
The output list can then be saved to the distributed filesystem, and the reducers run to merge the results. Again, it may be possible to run these in parallel, each reducing different keys.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        test_user: module: '@rybajs/metal/commons/test_user', local: true, auto: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', required: true
        yarn_client: module: '@rybajs/metal/hadoop/yarn_client', required: true
        yarn_nm: module: '@rybajs/metal/hadoop/yarn_nm', required: true
        yarn_rm: module: '@rybajs/metal/hadoop/yarn_rm', required: true
        yarn_tr: module: '@rybajs/metal/hadoop/yarn_tr'
        yarn_ts: module: '@rybajs/metal/hadoop/yarn_ts', single: true
        mapred_jhs: module: '@rybajs/metal/hadoop/mapred_jhs', single: true
      configure:
        '@rybajs/metal/hadoop/mapred_client/configure'
      commands:
        'check':
          '@rybajs/metal/hadoop/mapred_client/check'
        'report': [
          'masson/bootstrap/report'
          '@rybajs/metal/hadoop/mapred_client/report'
        ]
        'install': [
          '@rybajs/metal/hadoop/mapred_client/install'
          '@rybajs/metal/hadoop/mapred_client/check'
        ]
