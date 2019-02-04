
# Falcon Server

[Apache Falcon](http://falcon.apache.org) is a data processing and management solution for Hadoop designed
for data motion, coordination of data pipelines, lifecycle management, and data
discovery. Falcon enables end consumers to quickly onboard their data and its
associated processing and management tasks on Hadoop clusters.

    module.exports =
      use:
        krb5_client: implicit: true, module: 'masson/core/krb5_client'
        iptables: implicit: true, module: 'masson/core/iptables'
        java: implicit: true, module: 'masson/commons/java'
        test_user: implicit: true, module: '@rybajs/metal/commons/test_user'
        hdfs_nn: '@rybajs/metal/hadoop/hdfs_nn'
        hdfs_dn: '@rybajs/metal/hadoop/hdfs_dn'
        hcatalog: '@rybajs/metal/hive/hcatalog'
        falcon: '@rybajs/metal/falcon/server'
        oozie: '@rybajs/metal/oozie/server'
      configure:
        '@rybajs/metal/falcon/server/configure'  
      commands:
        'install': [
          '@rybajs/metal/falcon/server/install'
          '@rybajs/metal/falcon/server/start'
          '@rybajs/metal/falcon/server/check'
        ]
        'check':
          '@rybajs/metal/falcon/server/check'
        'start':
          '@rybajs/metal/falcon/server/start'
        'stop':
          '@rybajs/metal/falcon/server/stop'
        'status':
          '@rybajs/metal/falcon/server/status'

[falcon]: http://falcon.incubator.apache.org/
