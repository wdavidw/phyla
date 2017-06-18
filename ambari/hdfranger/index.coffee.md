
# Ranger with Ambari

    module.exports =
      use:
        ssl: module: 'masson/core/ssl'
        krb5_client: module: 'masson/core/krb5_client'
        java: module: 'masson/commons/java', recommanded: true
        hdf: module: 'ryba/hdf'
        hadoop: 'ryba/hadoop/core'
      configure: 'ryba/ambari/hdfranger/configure'
      commands:
        'install': ->
          options = @config.ambari_hdfranger
          @call 'ryba/ambari/ranger/install', options

[Ambari-server]: http://ambari.apache.org
