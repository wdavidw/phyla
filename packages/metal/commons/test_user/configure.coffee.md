
# Test User Configuration

    module.exports = (service) ->
      options = service.options

      options.force_check ?= false
      
## Unix Identity

      # Group
      options.group ?= {}
      options.group = name: options.group if typeof options.group is 'string'
      options.group.name ?= 'ryba'
      options.group.system ?= true
      # User
      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.name ?= 'ryba'
      options.user.home ?= "/home/#{options.user.name}"
      options.user.gid ?= options.group.name
      options.user.system ?= true
      options.user.comment ?= 'Ryba Test User'

## Kerberos Principal

      options.krb5 ?= {}
      options.krb5.realm ?= service.deps.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      # Admin Information
      options.krb5.admin = service.deps.krb5_client.options.admin[options.krb5.realm]
      # Kerberos user
      options.krb5.user ?= {}
      options.krb5.user = principal: options.krb5.user if typeof options.krb5.user is 'string'
      options.krb5.user.principal ?= options.user.name
      options.krb5.user.password ?= options.user.password if options.user.password?
      throw Error "Required Option: krb5.user.password" unless options.krb5.user.password
      options.krb5.user.principal = "#{options.krb5.user.principal}@#{options.krb5.realm}" unless /.+@.+/.test options.krb5.user.principal
