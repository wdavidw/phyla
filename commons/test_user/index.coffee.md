
# Test User

Create the Unix user and group as well as the Kerberos principal used for 
testing.

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true
      configure:
        'ryba/commons/test_user/configure'
      commands:
        'install':
          'ryba/commons/test_user/install'
