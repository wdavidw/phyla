
# Hive & HCatolog Client
[Hive Client](https://cwiki.apache.org/confluence/display/Hive/HiveClient) is the application that you use in order to administer, use Hive.
Once installed you can type hive in a prompt and the hive client shell wil launch directly.

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: 'ryba/hadoop/core/configure'
        hdfs_client: module: 'ryba/hadoop/hdfs_client'
        yarn_client: module: 'ryba/hadoop/yarn_client'
        mapred_client: 'ryba/hadoop/mapred_client'
        tez: implicit: true, module: 'ryba/tez'
        hcat: module: 'ryba/hive/hcatalog'
        ranger_admin: module: 'ryba/ranger/admin'
      configure:
        'ryba/hive/client/configure'
      commands:
        'install': [
          'ryba/hive/client/install'
          'ryba/hive/client/check'
        ]
        'check':
          'ryba/hive/client/check'
