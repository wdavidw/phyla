
# Test User

Create the Unix user and group as well as the Kerberos principal used for 
testing.

    module.exports =
      use:
        krb5_client: module: 'masson/core/krb5_client', local: true
      configure:
        'ryba/commons/test_user/configure'
      commands:
        'install': ->
          options = @config.ryba.test_user
          @call 'ryba/commons/test_user/install',
            group: options.group
            user: options.user
            krb5: options.krb5
