
# HDFS HttpFS

HttpFS is a server that provides a REST HTTP gateway supporting all HDFS File
System operations (read and write). And it is inteoperable with the webhdfs REST
HTTP API.

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        test_user: module: 'ryba/commons/test_user', local: true, auto: true, implicit: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        hdfs_dn: module: 'ryba/hadoop/hdfs_dn', required: true
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn', required: true
        hdfs_client: module: 'ryba/hadoop/hdfs_client', local: true, required: true # local: true, 
        httpfs: module: 'ryba/hadoop/httpfs'
      configure:
        'ryba/hadoop/httpfs/configure'
      commands:
        'check': ->
          options = @config.ryba.httpfs
          @call 'ryba/hadoop/httpfs/check', options
        'install': ->
          options = @config.ryba.httpfs
          @call 'ryba/hadoop/httpfs/install', options
          @call 'ryba/hadoop/httpfs/start', options
          @call 'ryba/hadoop/httpfs/check', options
        'start': ->
          options = @config.ryba.httpfs
          @call 'ryba/hadoop/httpfs/start', options
        'stop': ->
          options = @config.ryba.httpfs
          @call 'ryba/hadoop/httpfs/stop', options
        'status':
          'ryba/hadoop/httpfs/status'
