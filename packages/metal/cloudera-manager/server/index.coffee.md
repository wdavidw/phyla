
# Cloudera Manager Server

[Cloudera Manager Server][Cloudera-server-install] is the master host for the
cloudera manager software.
Once logged into the cloudera manager server host, the administrator can
provision, manage and monitor a Hadoop cluster.
You must have configured yum to use the [cloudera manager repo][Cloudera-manager-repo]
or the [cloudera cdh repo][Cloudera-cdh-repo].


    module.exports =
      deps:
        java: implicit: true, module: 'masson/commons/java'
        db_admin: implicit: true, module: '@rybajs/metal/commons/db_admin'
      configure:
        '@rybajs/metal/cloudera-manager/server/configure'
      commands:
        'install': [
          '@rybajs/metal/cloudera-manager/server/install'
          '@rybajs/metal/cloudera-manager/server/start'
        ]
        'prepare': ->
          @call
            if: -> @contexts('@rybajs/metal/cloudera_manager/server')[0]?.config.host is @config.host
            ssh: false
            distrib: @config.cloudera_manager.distrib
            services: @config.cloudera_manager.distrib
          , '@rybajs/metal/cloudera-manager/server/prepare'
        'start':
          '@rybajs/metal/cloudera-manager/server/start'
        'stop':
          '@rybajs/metal/cloudera-manager/server/stop'

[Cloudera-server-install]: http://www.cloudera.com/content/www/en-us/documentation/enterprise/5-2-x/topics/cm_ig_install_path_b.html#cmig_topic_6_6_4_unique_1
[Cloudera-manager-repo]: http://archive.cloudera.com/cm5/redhat/6/x86_64/cm/cloudera-manager.repo
[Cloudera-cdh-repo]: http://archive.cloudera.com/cdh5/redhat/6/x86_64/cdh/cloudera-cdh5.repo
