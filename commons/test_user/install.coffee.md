
# Test User Install

    module.exports = header: 'Test User Install', handler: (options) ->
      
## Unix Identity

Create a Unix and Kerberos test user, by default "ryba". Its HDFS home directory
will be created by one of the datanode.

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Kerberos Principal

      @krb5.addprinc 
        header: 'Kerberos Principal'
      , options.krb5.admin
      , options.krb5.user
