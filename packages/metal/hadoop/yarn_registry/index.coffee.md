
# Apache Yarn Registry

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server'
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', required: true
        mapred_jhs: module: '@rybajs/metal/hadoop/mapred_jhs', single: true
        yarn_ts: module: '@rybajs/metal/hadoop/yarn_ts'
        yarn_tr: module: '@rybajs/metal/hadoop/yarn_tr'
        yarn_nm: module: '@rybajs/metal/hadoop/yarn_nm'
        yarn_rm: module: '@rybajs/metal/hadoop/yarn_rm'
        yarn_client: module: '@rybajs/metal/hadoop/yarn_client'
      configure:
        '@rybajs/metal/hadoop/yarn_registry/configure'
      commands:
        install: [
          '@rybajs/metal/hadoop/yarn_registry/install'
          '@rybajs/metal/hadoop/yarn_registry/start'
        ]
