
# Tez

[Apache Tez][tez] is aimed at building an application framework which allows for
a complex directed-acyclic-graph of tasks for processing data. It is currently
built atop Apache Hadoop YARN.

## Commands

    module.exports =
      deps:
        java: module: 'masson/commons/java', local: true
        httpd: module: 'masson/commons/httpd', local: true
        test_user: module: '@rybajs/metal/commons/test_user', local: true, auto: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', local: true, auto: true, implicit: true
        yarn_nm: module: '@rybajs/metal/hadoop/yarn_nm', required: true
        yarn_rm: module: '@rybajs/metal/hadoop/yarn_rm', required: true
        yarn_ts: module: '@rybajs/metal/hadoop/yarn_ts'
        yarn_tr: module: '@rybajs/metal/hadoop/yarn_tr'
        yarn_client: module: '@rybajs/metal/hadoop/yarn_client', local: true, auto: true, implicit: true
      configure:
        '@rybajs/metal/tez/configure'
      commands:
        'install': [
          '@rybajs/metal/tez/install'
          '@rybajs/metal/tez/check'
        ]
        'check':
          '@rybajs/metal/tez/check'

[tez]: http://tez.apache.org/
[instructions]: (http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.0/HDP_Man_Install_v22/index.html#Item1.8.4)
