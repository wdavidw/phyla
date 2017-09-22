
# Ranger with Ambari

    module.exports =
      use:
        ssl: module: 'masson/core/ssl'
        krb5_client: module: 'masson/core/krb5_client', local: true
        java: module: 'masson/commons/java', local: true
        hdf: module: 'ryba/hdf', local: true
        ambari_repo: module: 'ryba/ambari/hdfrepo', local: true, implicit: true
        hadoop_core: module: 'ryba/hadoop/core'
      configure: 'ryba/ambari/hdfranger/configure'
      commands:
        'install': ->
          options = @config.ryba.ambari.hdfranger
          @call 'ryba/ambari/ranger/install', options

[Ambari-server]: http://ambari.apache.org
