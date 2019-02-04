
# YARN Client

The [Hadoop YARN Client](http://hadoop.apache.org/docs/current/hadoop-yarn/hadoop-yarn-site/WebServicesIntro.html) web service REST APIs are a set of URI resources that give access to the cluster, nodes, applications, and application historical information.
The URI resources are grouped into APIs based on the type of information returned. Some URI resources return collections while others return singletons.

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        test_user: module: '@rybajs/metal/commons/test_user', local: true, auto: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', required: true
        yarn_nm: module: '@rybajs/metal/hadoop/yarn_nm', required: true
        yarn_rm: module: '@rybajs/metal/hadoop/yarn_rm', required: true
        yarn_ts: module: '@rybajs/metal/hadoop/yarn_ts'
        yarn_tr: module: '@rybajs/metal/hadoop/yarn_tr'
      configure:
        '@rybajs/metal/hadoop/yarn_client/configure'
      commands:
        'check':
          '@rybajs/metal/hadoop/yarn_client/check'
        'install': [
          '@rybajs/metal/hadoop/yarn_client/install'
          '@rybajs/metal/hadoop/yarn_client/check'
        ]
        'report': [
          'masson/bootstrap/report'
          '@rybajs/metal/hadoop/yarn_client/report'
        ]
