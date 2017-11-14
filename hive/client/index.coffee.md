
# Hive & HCatolog Client

[Hive Client](https://cwiki.apache.org/confluence/display/Hive/HiveClient) is the application that you use in order to administer, use Hive.
Once installed you can type hive in a prompt and the hive client shell wil launch directly.

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        test_user: module: 'ryba/commons/test_user', local: true, auto: true, implicit: true
        hadoop_core: module: 'ryba/hadoop/core/configure'
        hdfs_client: module: 'ryba/hadoop/hdfs_client'
        yarn_client: module: 'ryba/hadoop/yarn_client'
        mapred_client: 'ryba/hadoop/mapred_client'
        tez: module: 'ryba/tez', local: true, auto: true, implicit: true
        hive_hcatalog: module: 'ryba/hive/hcatalog'
        phoenix_client: module: 'ryba/phoenix/client', local: true
        ranger_admin: module: 'ryba/ranger/admin', single: true
        ranger_hdfs: module: 'ryba/ranger/plugins/hdfs'
      configure:
        'ryba/hive/client/configure'
      commands:
        'install': [
          'ryba/hive/client/install'
          'ryba/hive/client/check'
        ]
        'check':
          'ryba/hive/client/check'
