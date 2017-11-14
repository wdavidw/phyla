# Apache Zeppelin

Zeppelin is a web-based notebook that enables interactive data analytics. You 
can make beautiful data-driven, interactive and collaborative documents with 
SQL, Scala and more. 

    module.exports =
      deps:
        'docker': module: 'masson/commons/docker', local: true, auto: true
        # 'hadoop_core': module: 'ryba/hadoop/core', local: true, auto: true
        'hdfs_client': module: 'ryba/hadoop/hdfs_client', local: true, auto: true
        'spark_client': module: 'ryba/spark/client', local: true, auto: true
        'hive_client': module: 'ryba/hive/client', local: true, auto: true
      configure:
        'ryba/zeppelin/configure'
      commands:
        'prepare':
          'ryba/zeppelin/prepare'
        'install':
          'ryba/zeppelin/install'
