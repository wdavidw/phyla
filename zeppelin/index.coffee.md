# Apache Zeppelin

Zeppelin is a web-based notebook that enables interactive data analytics. You 
can make beautiful data-driven, interactive and collaborative documents with 
SQL, Scala and more. 

    module.exports =
      use:
        'docker': module: 'masson/commons/docker', local: true, auto: true, implicit: true
        # 'hadoop_core': module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        'hdfs_client': module: 'ryba/hadoop/hdfs_client', local: true, auto: true, implicit: true
        'spark_client': module: 'ryba/spark/client', local: true, auto: true, implicit: true
        'hive_client': module: 'ryba/hive/client', local: true, auto: true, implicit: true
      configure:
        'ryba/zeppelin/configure'
      commands:
        'prepare': ->
          options = @config.ryba.zeppelin
          @call 'ryba/zeppelin/prepare', options
        'install': ->
          options = @config.ryba.zeppelin
          @call 'ryba/zeppelin/install', options
