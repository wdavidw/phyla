# Ranger HDFS Plugin

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client'
      configure:
        'ryba/ranger/plugins/yarn/configure'
