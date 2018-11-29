
# Apache Yarn Registry

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        zookeeper_server: module: 'ryba/zookeeper/server'
        hdfs_client: module: 'ryba/hadoop/hdfs_client', required: true
        mapred_jhs: module: 'ryba/hadoop/mapred_jhs', single: true
        yarn_ts: module: 'ryba/hadoop/yarn_ts'
        yarn_tr: module: 'ryba/hadoop/yarn_tr'
        yarn_nm: module: 'ryba/hadoop/yarn_nm'
        yarn_rm: module: 'ryba/hadoop/yarn_rm'
        yarn_client: module: 'ryba/hadoop/yarn_client'
      configure:
        'ryba/hadoop/yarn_registry/configure'
      commands:
        install: [
          'ryba/hadoop/yarn_registry/install'
          'ryba/hadoop/yarn_registry/start'
        ]
