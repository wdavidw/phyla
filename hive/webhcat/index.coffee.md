
# WebHCat

[WebHCat](https://cwiki.apache.org/confluence/display/Hive/WebHCat) is a REST API for HCatalog. (REST stands for "representational state transfer", a style of API based on HTTP verbs).  The original name of WebHCat was Templeton.

    module.exports =
      use:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        test_user: module: 'ryba/commons/test_user', local: true, auto: true, implicit: true
        hadoop_core: module: 'ryba/hadoop/core'
        hive_client: module: 'ryba/hive/client', implicit: true, 
        hive_hcatalog: module: 'ryba/hive/hcatalog'
        sqoop: module: 'ryba/sqoop'
        db_admin: module: 'ryba/commons/db_admin'
      configure:
        'ryba/hive/webhcat/configure'
      commands:
        'install': [
          'ryba/hive/webhcat/install'
          'ryba/hive/webhcat/start'
          'ryba/hive/webhcat/check'
        ]
        'start':
          'ryba/hive/webhcat/start'
        'status':
          'ryba/hive/webhcat/status'
        'stop':
          'ryba/hive/webhcat/stop'
        'wait':
          'ryba/hive/webhcat/wait'
