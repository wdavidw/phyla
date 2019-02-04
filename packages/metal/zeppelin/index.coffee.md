# Apache Zeppelin

Zeppelin is a web-based notebook that enables interactive data analytics. You 
can make beautiful data-driven, interactive and collaborative documents with 
SQL, Scala and more. 

    module.exports =
      deps:
        'docker': module: 'masson/commons/docker', local: true, auto: true
        # 'hadoop_core': module: '@rybajs/metal/hadoop/core', local: true, auto: true
        'hdfs_client': module: '@rybajs/metal/hadoop/hdfs_client', local: true, auto: true
        'spark_client': module: '@rybajs/metal/spark/client', local: true, auto: true
        'hive_client': module: '@rybajs/metal/hive/client', local: true, auto: true
      configure:
        '@rybajs/metal/zeppelin/configure'
      commands:
        'prepare':
          '@rybajs/metal/zeppelin/prepare'
        'install':
          '@rybajs/metal/zeppelin/install'
