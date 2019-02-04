
# WebHCat

[WebHCat](https://cwiki.apache.org/confluence/display/Hive/WebHCat) is a REST API for HCatalog. (REST stands for "representational state transfer", a style of API based on HTTP verbs).  The original name of WebHCat was Templeton.

    module.exports =
      deps:
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        db_admin: module: '@rybajs/metal/commons/db_admin'
        test_user: module: '@rybajs/metal/commons/test_user', local: true, auto: true, implicit: true
        zookeeper_server: module: '@rybajs/metal/zookeeper/server', required: true
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, required: true
        hive_hcatalog: module: '@rybajs/metal/hive/hcatalog', required: true
        hive_client: module: '@rybajs/metal/hive/client', local: true, auto: true, implicit: true
        hive_webhcat: module: '@rybajs/metal/hive/webhcat'
        sqoop: module: '@rybajs/metal/sqoop'
        log4j: module: '@rybajs/metal/log4j', local: true
      configure:
        '@rybajs/metal/hive/webhcat/configure'
      commands:
        'install': [
          '@rybajs/metal/hive/webhcat/install'
          '@rybajs/metal/hive/webhcat/start'
          '@rybajs/metal/hive/webhcat/check'
        ]
        'start':
          '@rybajs/metal/hive/webhcat/start'
        'status':
          '@rybajs/metal/hive/webhcat/status'
        'stop':
          '@rybajs/metal/hive/webhcat/stop'
