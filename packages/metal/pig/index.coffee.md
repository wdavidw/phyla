
# Pig

[Apache Pig](https://pig.apache.org/) is a platform for analyzing large data sets that consists of a
high-level language for expressing data analysis programs, coupled with
infrastructure for evaluating these programs. The salient property of Pig
programs is that their structure is amenable to substantial parallelization,
which in turns enables them to handle very large data sets.

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true, implicit: true
        test_user: module: '@rybajs/metal/commons/test_user', local: true, auto: true
        yarn_rm: module: '@rybajs/metal/hadoop/yarn_rm', required: true
        yarn_client: module: '@rybajs/metal/hadoop/yarn_client', local: true, auto: true, implicit: true
        mapred_client: module: '@rybajs/metal/hadoop/mapred_client', local: true, auto: true, implicit: true
        hive_client: module: '@rybajs/metal/hive/client', local: true, required: true # In case pig is run through hcat
      configure:
        '@rybajs/metal/pig/configure'
      commands:
        'check':
          '@rybajs/metal/pig/check'
        'install': [
          '@rybajs/metal/pig/install'
          '@rybajs/metal/pig/check'
        ]
