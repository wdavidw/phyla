
# YARN Client

The [Hadoop YARN Client](http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/WebServicesIntro.html) web service REST APIs are a set of URI resources that give access to the cluster, nodes, applications, and application historical information.
The URI resources are grouped into APIs based on the type of information returned. Some URI resources return collections while others return singletons.

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', required: true
        yarn_nm: module: 'ryba/hadoop/yarn_nm', required: true
        yarn_rm: module: 'ryba/hadoop/yarn_rm', required: true
        yarn_ts: module: 'ryba/hadoop/yarn_ts'
      configure:
        'ryba/hadoop/yarn_client/configure'
      commands:
        'check': ->
          options = @config.ryba.yarn_client
          @call 'ryba/hadoop/yarn_client/check', options
        'install': ->
          options = @config.ryba.yarn_client
          @call 'ryba/hadoop/yarn_client/install', options
          @call 'ryba/hadoop/yarn_client/check', options
        'report': ->
          options = @config.ryba.yarn_client
          @call 'masson/bootstrap/report', options
          @call 'ryba/hadoop/yarn_client/report', options
