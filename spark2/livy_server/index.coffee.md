
# Livy Spark Server (Dockerized)

[Livy Spark Server][livy] is a rest interface to interact with  Apache Spark.
It used by [Hue][home] to provide users a spark application  notebook.

This modules builds the livy spark server in a container and should be used in combination
with ryba/huedocker to provided end to end setup.
It can also be used with any other hue installation, or even any other application.

You should start with /bin/ryba prepare -m 'ryba/spark2/livy_server' command first.

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client'
        'java': implicit: true, module: 'masson/commons/java'
        'hadoop': 'ryba/hadoop/core'
        'spark': 'ryba/spark2/client'
      configure:
        'ryba/spark2/livy_server/configure'
      commands:
        'prepare':
          'ryba/spark2/livy_server/prepare'
        'install': [
          'ryba/spark2/livy_server/install'
          'ryba/spark2/livy_server/wait'
        ]
        'start':
          'ryba/spark2/livy_server/start'
        'stop':
          'ryba/spark2/livy_server/stop'
        # 'status':
        #   'ryba/spark2/livy_server/status'

[home]: http://gethue.com
[livy]: https://github.com/cloudera/livy
