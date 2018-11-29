
# YARN Timeline Server

The [Yarn Timeline Server][ts] store and retrieve current as well as historic
information for the applications running inside YARN.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', auto: true
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn', required: true
        yarn_rm: module: 'ryba/hadoop/yarn_rm', required: true
        yarn_ts: module: 'ryba/hadoop/yarn_ts'
      configure:
        'ryba/hadoop/yarn_ts/configure'
      commands:
        'check':
          'ryba/hadoop/yarn_ts/check'
        'install': [
          'ryba/hadoop/yarn_ts/install'
          'ryba/hadoop/yarn_ts/start'
          'ryba/hadoop/yarn_ts/check'
        ]
        'start':
          'ryba/hadoop/yarn_ts/start'
        'status':
          'ryba/hadoop/yarn_ts/status'
        'stop':
          'ryba/hadoop/yarn_ts/stop'

[ts]: http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/TimelineServer.html
