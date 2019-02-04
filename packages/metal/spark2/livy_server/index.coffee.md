
# Livy Spark Server (Dockerized)

[Livy Spark Server][livy] is a rest interface to interact with  Apache Spark.
It used by [Hue][home] to provide users a spark application  notebook.

This modules builds the livy spark server in a container and should be used in combination
with @rybajs/metal/huedocker to provided end to end setup.
It can also be used with any other hue installation, or even any other application.

You should start with /bin/ryba prepare -m '@rybajs/metal/spark2/livy_server' command first.

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client'
        'java': implicit: true, module: 'masson/commons/java'
        'hadoop': '@rybajs/metal/hadoop/core'
        'spark': '@rybajs/metal/spark2/client'
      configure:
        '@rybajs/metal/spark2/livy_server/configure'
      commands:
        'prepare':
          '@rybajs/metal/spark2/livy_server/prepare'
        'install': [
          '@rybajs/metal/spark2/livy_server/install'
          '@rybajs/metal/spark2/livy_server/wait'
        ]
        'start':
          '@rybajs/metal/spark2/livy_server/start'
        'stop':
          '@rybajs/metal/spark2/livy_server/stop'
        # 'status':
        #   '@rybajs/metal/spark2/livy_server/status'

[home]: http://gethue.com
[livy]: https://github.com/cloudera/livy
