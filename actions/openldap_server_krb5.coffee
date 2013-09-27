
###
OpenLDAP Kerberos
=================

###
ldap = require 'ldapjs'
misc = require 'mecano/lib/misc'
module.exports = []

###
Configuration
-------------

We rely on "histi/actions/openldap_server" to get "config_dn"
and "config_password".

We rely on "histi/actions/krb5_server" to get "ldap_kadmind_dn",
"manager_dn" and "manager_password".

We make sure to set "ctx.ldap_admin" which isn't present in
force mode.
###
module.exports.push (ctx, next) ->
  openldap_server = require './openldap_server'
  openldap_server.configure ctx
  krb5_server = require './krb5_server'
  krb5_server.configure ctx
  # Configure openldap_krb5
  {groups_container_dn, admin_group, users_container_dn, admin_user} = ctx.config.openldap_krb5
  ctx.config.openldap_krb5.admin_user = misc.merge {}, admin_user,
    cn: /^cn=(.*?),/.exec(users_container_dn)[1]
    objectClass: [
      'top', 'inetOrgPerson', 'organizationalPerson',
      'person', 'posixAccount'
    ]
    givenName: 'Kerberos Administrator'
    mail: 'kerberos.admin@company.com'
    sn: 'krbadmin'
    uid: 'krbadmin'
    uidNumber: '800'
    gidNumber: '800'
    homeDirectory: '/home/krbadmin'
    loginShell: '/bin/false'
    displayname: 'Kerberos Administrator'
    userPassword: '{SSHA}uQcSsw5CySTkBXjOY/N0hcduA6yFiI0k' #test
  ctx.config.openldap_krb5.admin_group = misc.merge {}, admin_group,
    cn: /^cn=(.*?),/.exec(groups_container_dn)[1]
    objectClass: [ 'top', 'posixGroup' ]
    gidNumber: '800'
    description: 'Kerberos administrator\'s group.'
  # Create LDAP admin connection if not already present
  return next() if ctx.ldap_admin
  openldap_connect = require './openldap_connection'
  openldap_connect.connect ctx, next

###
Install schema
--------------

Prepare and deploy the kerberos schema. Upon installation, it
is possible to check if the schema is installed by calling
the command `ldapsearch  -D cn=admin,cn=config -w test -b "cn=config"`.
###
module.exports.push (ctx, next) ->
  @name 'OpenLDAP Kerberos # Install schema'
  @timeout -1
  conf = '/tmp/kerberos_schema/schema.conf'
  ldif = '/tmp/kerberos_schema/ldif'
  {config_dn, config_password} = ctx.config.openldap_server
  install = ->
    ctx.log 'Install schema'
    ctx.service
      name: 'krb5-server-ldap'
    , (err, serviced) ->
      return next err if err
      locate()
  locate = ->
    ctx.log 'Get schema location'
    ctx.execute
      cmd: 'rpm -ql krb5-server-ldap | grep kerberos.schema'
    , (err, executed, schema) ->
      return next err if err
      return next Error 'Sudo schema not found' if schema is ''
      register schema
  register = (schema) ->
    ctx.ldap_schema
      # ldap: ctx.ldap_config
      name: 'kerberos'
      schema: schema
      binddn: config_dn
      passwd: config_password
      log: ctx.log
    , (err, registered) ->
      next err, if registered then ctx.OK else ctx.PASS
  install()

module.exports.push (ctx, next) ->
  @name 'OpenLDAP Kerberos # Insert data'
  {realms_dn, groups_container_dn, admin_group, users_container_dn, admin_user} = ctx.config.openldap_krb5
  modified = false
  kbsou = ->
    ctx.log 'Create the kerberos organisational unit'
    ctx.ldap_admin.add realms_dn, 
      ou: /^ou=(.*?),/.exec(realms_dn)[1]
      objectClass: [ 'top', 'organizationalUnit' ]
      description: 'Kerberos OU to store Kerberos principals.'
    , (err, search) ->
      return done err if err and err.name isnt 'EntryAlreadyExistsError'
      modified = true unless err
      kadmg()
  kadmg = ->
    ctx.log 'Create the kerberos administrator\'s group'
    ctx.ldap_admin.add groups_container_dn, admin_group, (err, search) ->
      return done err if err and err.name isnt 'EntryAlreadyExistsError'
      modified = true unless err
      kadmu()
  kadmu = ->
    ctx.log 'Create the kerberos administrator\'s user'
    ctx.ldap_admin.add users_container_dn, admin_user, (err, search) ->
      return done err if err and err.name isnt 'EntryAlreadyExistsError'
      modified = true unless err
      done()
  done = (err) ->
    next err, if modified then ctx.OK else ctx.PASS
  kbsou()

module.exports.push (ctx, next) ->
  @name 'OpenLDAP Kerberos # User permissions for kerberos'
  {realms_dn, users_container_dn} = ctx.config.openldap_krb5
  ctx.ldap_acl [
    ldap: ctx.ldap_config
    log: ctx.log
    name: "olcDatabase={2}bdb,cn=config"
    before: "dn.subtree=\"dc=adaltas,dc=com\""
    to: "dn.subtree=\"#{realms_dn}\""
    by: [
      "dn.exact=\"#{users_container_dn}\" write"
      "dn.base=\"gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth\" read"
      "* none"
    ]
  ,
    ldap: ctx.ldap_config
    log: ctx.log
    name: "olcDatabase={2}bdb,cn=config"
    to: "dn.subtree=\"dc=adaltas,dc=com\""
    by: [
      "dn.exact=\"#{users_container_dn}\" write"
    ]
  ], (err, modified) ->
    return next err if err
    ctx.log 'Check it returns the entire ou=kerberos,ou=services,dc=company,dc=com subtree'
    ctx.execute
      cmd: "ldapsearch -xLLLD #{users_container_dn} -w test -b ou=kerberos,ou=services,ou=lot1,dc=adaltas,dc=com"
    , (err) ->
      # Nice but no garanty that a "nssproxy" user exists. I keep it
      # for now because it would be great to test permission
      # return next err if err
      # ctx.log 'Check it return the « No such object (32) » error'
      # ldapsearch -xLLLD cn=nssproxy,ou=users,dc=adaltas,dc=com -w test -bou=kerberos,ou=services,ou=lot1,dc=adaltas,dc=com dn
      # ctx.execute
      #   cmd: "ldapsearch -xLLLD cn=nssproxy,ou=users,dc=adaltas,dc=com -w test -bou=kerberos,ou=services,ou=lot1,dc=adaltas,dc=com dn"
      #   code: 32
      # , (err) ->
      #   next err, if modified then ctx.OK else ctx.PASS
      next err, if modified then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'OpenLDAP Kerberos # Index'
  ctx.ldap_index
    ldap: ctx.ldap_config
    name: "olcDatabase={2}bdb,cn=config"
    indexes:
      krbPrincipalName: 'sub,eq'
  , (err, indexed) ->
    next err, if indexed then ctx.OK else ctx.PASS








