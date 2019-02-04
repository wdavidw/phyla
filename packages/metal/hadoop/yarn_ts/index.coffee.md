
# YARN Timeline Server

The [Yarn Timeline Server][ts] store and retrieve current as well as historic
information for the applications running inside YARN.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', auto: true
        hdfs_nn: module: '@rybajs/metal/hadoop/hdfs_nn', required: true
        yarn_rm: module: '@rybajs/metal/hadoop/yarn_rm', required: true
        yarn_ts: module: '@rybajs/metal/hadoop/yarn_ts'
      configure:
        '@rybajs/metal/hadoop/yarn_ts/configure'
      commands:
        'check':
          '@rybajs/metal/hadoop/yarn_ts/check'
        'install': [
          '@rybajs/metal/hadoop/yarn_ts/install'
          '@rybajs/metal/hadoop/yarn_ts/start'
          '@rybajs/metal/hadoop/yarn_ts/check'
        ]
        'start':
          '@rybajs/metal/hadoop/yarn_ts/start'
        'status':
          '@rybajs/metal/hadoop/yarn_ts/status'
        'stop':
          '@rybajs/metal/hadoop/yarn_ts/stop'

[ts]: http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/TimelineServer.html
