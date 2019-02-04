
# Falcon Client

[Apache Falcon](http://falcon.apache.org) is a data processing and management solution for Hadoop designed
for data motion, coordination of data pipelines, lifecycle management, and data
discovery. Falcon enables end consumers to quickly onboard their data and its
associated processing and management tasks on Hadoop clusters.

    module.exports =
      use:
        hadoop_core: module: '@rybajs/metal/hadoop/core', local: true, auto: true
        krb5_client: module: 'masson/core/krb5_client', local: true, auto: true
        test_user: module: '@rybajs/metal/commons/test_user', local: true, auto: true
      configure:
        '@rybajs/metal/falcon/client/configure'
      commands:
        'install': [
          '@rybajs/metal/falcon/client/install'
          '@rybajs/metal/falcon/client/check'
        ]
        'check':
          '@rybajs/metal/falcon/client/check'

[falcon]: http://falcon.incubator.apache.org/
