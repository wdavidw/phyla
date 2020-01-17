
# Hue

[Hue][home] features a File Browser for HDFS, a Job Browser for MapReduce/YARN,
an HBase Browser, query editors for Hive, Pig, Cloudera Impala and Sqoop2.
It also ships with an Oozie Application for creating and monitoring workflows,
a Zookeeper Browser and a SDK.

Link to configure [hive hue configuration][hive-hue-ssl] over ssl.

    module.exports =
      deps:
        db_admin: module: '@rybajs/tools/db_admin', local: true, auto: true, implicit: true
        iptables: implicit: true, module: 'masson/core/iptables'
        nodejs: module: '@rybajs/system/nodejs', local: true, auto: true, implicit: true
        krb5_client: module: 'masson/core/krb5_client'
        ipa_client: module: 'masson/core/freeipa/client', local: true
      configure:
        '@rybajs/tools/hue/configure'
      commands:
        'backup': [
          '@rybajs/tools/hue/backup'
        ]
        'install': [
          '@rybajs/tools/hue/install'
          '@rybajs/tools/hue/start'
        ]
        'start': [
          '@rybajs/tools/hue/start'
        ]
        'status': [
          '@rybajs/tools/hue/status'
        ]
        'stop': [
          '@rybajs/tools/hue/stop'
        ]

[home]: http://gethue.com
[hive-hue-ssl]:(http://www.cloudera.com/content/www/en-us/documentation/cdh/5-0-x/CDH5-Security-Guide/cdh5sg_hue_security.html)
