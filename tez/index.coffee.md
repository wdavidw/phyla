
# Tez

[Apache Tez][tez] is aimed at building an application framework which allows for
a complex directed-acyclic-graph of tasks for processing data. It is currently
built atop Apache Hadoop YARN.

## Commands

    module.exports =
      deps:
        java: module: 'masson/commons/java', local: true
        httpd: module: 'masson/commons/httpd', local: true
        test_user: module: 'ryba/commons/test_user', local: true, auto: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', local: true, auto: true, implicit: true
        yarn_nm: module: 'ryba/hadoop/yarn_nm', required: true
        yarn_rm: module: 'ryba/hadoop/yarn_rm', required: true
        yarn_ts: module: 'ryba/hadoop/yarn_ts'
        yarn_tr: module: 'ryba/hadoop/yarn_tr'
        yarn_client: module: 'ryba/hadoop/yarn_client', local: true, auto: true, implicit: true
      configure:
        'ryba/tez/configure'
      commands:
        'install': [
          'ryba/tez/install'
          'ryba/tez/check'
        ]
        'check':
          'ryba/tez/check'

[tez]: http://tez.apache.org/
[instructions]: (http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.2.0/HDP_Man_Install_v22/index.html#Item1.8.4)
