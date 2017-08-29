
# YARN Timeline Server

The [Yarn Timeline Server][ts] store and retrieve current as well as historic
information for the applications running inside YARN.

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, required: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', auto: true
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn', required: true
        yarn_nm: module: 'ryba/hadoop/yarn_nm', required: true
        # yarn_client: 'ryba/hadoop/yarn_client'
      configure:
        'ryba/hadoop/yarn_ts/configure'
      commands:
        'check':->
          options = @config.ryba.yarn.ats
          @call 'ryba/hadoop/yarn_ts/check', options
        'install': ->
          options = @config.ryba.yarn.ats
          @call 'ryba/hadoop/yarn_ts/install', options
          @call 'ryba/hadoop/yarn_ts/start', options
          @call 'ryba/hadoop/yarn_ts/check', options
        'start': ->
          options = @config.ryba.yarn.ats
          @call 'ryba/hadoop/yarn_ts/start', options
        'status':
          'ryba/hadoop/yarn_ts/status'
        'stop': ->
          options = @config.ryba.yarn.ats
          @call 'ryba/hadoop/yarn_ts/stop', options

[ts]: http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/TimelineServer.html
