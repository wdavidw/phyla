
# HDFS HttpFS

HttpFS is a server that provides a REST HTTP gateway supporting all HDFS File
System operations (read and write). And it is inteoperable with the webhdfs REST
HTTP API.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        test_user: module: '@rybajs/metal/commons/test_user', local: true, auto: true, implicit: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        hdfs_dn: module: '@rybajs/metal/hadoop/hdfs_dn', required: true
        hdfs_nn: module: '@rybajs/metal/hadoop/hdfs_nn', required: true
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client', local: true, auto: true
        httpfs: module: '@rybajs/metal/hadoop/httpfs'
        log4j: module: '@rybajs/metal/log4j', local: true
      configure:
        '@rybajs/metal/hadoop/httpfs/configure'
      commands:
        'check':
          '@rybajs/metal/hadoop/httpfs/check'
        'install': [
          '@rybajs/metal/hadoop/httpfs/install'
          '@rybajs/metal/hadoop/httpfs/start'
          '@rybajs/metal/hadoop/httpfs/check'
        ]
        'start':
          '@rybajs/metal/hadoop/httpfs/start'
        'stop':
          '@rybajs/metal/hadoop/httpfs/stop'
        'status':
          '@rybajs/metal/hadoop/httpfs/status'
