
# Hive & HCatolog Client

[Hive Client](https://cwiki.apache.org/confluence/display/Hive/HiveClient) is the application that you use in order to administer, use Hive.
Once installed you can type hive in a prompt and the hive client shell wil launch directly.

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        test_user: module: '@rybajs/metal/commons/test_user', local: true, auto: true, implicit: true
        hadoop_core: module: '@rybajs/metal/hadoop/core/configure'
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client'
        yarn_client: module: '@rybajs/metal/hadoop/yarn_client'
        mapred_client: '@rybajs/metal/hadoop/mapred_client'
        tez: module: '@rybajs/metal/tez', local: true, auto: true, implicit: true
        hive_hcatalog: module: '@rybajs/metal/hive/hcatalog'
        phoenix_client: module: '@rybajs/metal/phoenix/client', local: true
        ranger_admin: module: '@rybajs/metal/ranger/admin', single: true
        ranger_hdfs: module: '@rybajs/metal/ranger/plugins/hdfs'
      configure:
        '@rybajs/metal/hive/client/configure'
      commands:
        'install': [
          '@rybajs/metal/hive/client/install'
          '@rybajs/metal/hive/client/check'
        ]
        'check':
          '@rybajs/metal/hive/client/check'
