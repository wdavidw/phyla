
# Pig

[Apache Pig](https://pig.apache.org/) is a platform for analyzing large data sets that consists of a
high-level language for expressing data analysis programs, coupled with
infrastructure for evaluating these programs. The salient property of Pig
programs is that their structure is amenable to substantial parallelization,
which in turns enables them to handle very large data sets.

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        hadoop_core: module: 'ryba/hadoop/core', local: true, auto: true, implicit: true
        test_user: module: 'ryba/commons/test_user', local: true, auto: true, implicit: true
        yarn_rm: module: 'ryba/hadoop/yarn_rm', required: true
        yarn_client: module: 'ryba/hadoop/yarn_client', local: true, auto: true, implicit: true
        mapred_client: module: 'ryba/hadoop/mapred_client', local: true, auto: true, implicit: true
        hive_client: module: 'ryba/hive/client', local: true, auto: true, implicit: true # In case pig is run through hcat
      configure:
        'ryba/pig/configure'
      commands:
        'check': ->
          options = @config.ryba.pig
          @call 'ryba/pig/check', options
        'install': ->
          options = @config.ryba.pig
          @call 'ryba/pig/install', options
          @call 'ryba/pig/check', options
