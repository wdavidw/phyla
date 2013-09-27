
misc = require 'mecano/lib/misc'
mkprincipal = require './krb5/lib/mkprincipal'
# krb = require './krb'
module.exports = []

module.exports.push 'histi/actions/yum'
module.exports.push 'histi/actions/ssh'
module.exports.push 'histi/actions/ntp'

###
Goals
    Enable sshd(8) Kerberos authentication.
    Enable PAM Kerberos authentication.
    SASL GSSAPI OpenLDAP authentication.
    Use SAS:L GSSAPI Authentication with AutoFS.
IMPORTANT : Kerberos clients require connectivity to the KDC's TCP ports 88 and 749.

###

module.exports.push module.exports.configure = (ctx) ->
  # krb.configure ctx
  ctx.config.krb5_client ?= {}
  throw new Error "Kerberos property realm is required" unless ctx.config.krb5_client.realm
  ctx.config.krb5_client.realm = ctx.config.krb5_client.realm.toUpperCase()
  unless ctx.config.krb5_client.etc_krb5_conf
    REALM = ctx.config.krb5_client.realm
    realm = REALM.toLowerCase()
    etc_krb5_conf =
      'logging':
        'default': 'SYSLOG:INFO:LOCAL1'
        'kdc': 'SYSLOG:NOTICE:LOCAL1'
        'admin_server': 'SYSLOG:WARNING:LOCAL1'
      'libdefaults': 
        'default_realm': REALM
        'dns_lookup_realm': false
        'dns_lookup_kdc': false
        'ticket_lifetime': '24h'
        'renew_lifetime': '7d'
        'forwardable': true
      'realms': {}
      'domain_realm': {}
      'appdefaults':
        'pam':
          'debug': false
          'ticket_lifetime': 36000
          'renew_lifetime': 36000
          'forwardable': true
          'krb4_convert': false
    etc_krb5_conf.realms["#{REALM}"] = 
      'kdc': ctx.config.krb5_client.kdc or realm
      'admin_server': ctx.config.krb5_client.admin_server or realm
      'default_domain': ctx.config.krb5_client.default_domain or realm
    etc_krb5_conf.domain_realm[".#{realm}"] = REALM
    etc_krb5_conf.domain_realm["#{realm}"] = REALM
    ctx.config.krb5_client.etc_krb5_conf = etc_krb5_conf
  ctx.config.krb5_client.sshd ?= {}
  ctx.config.krb5_client.sshd = misc.merge
    ChallengeResponseAuthentication: 'yes'
    KerberosAuthentication: 'yes'
    KerberosOrLocalPasswd: 'yes'
    KerberosTicketCleanup: 'yes'
    GSSAPIAuthentication: 'yes'
    GSSAPICleanupCredentials: 'yes'
  , ctx.config.krb5_client.sshd

module.exports.push (ctx, next) ->
  @name 'Kerberos client # Install'
  ctx.service [
    name: 'krb5-workstation'
  ], (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  # Kerberos config is also managed by the kerberos server action.
  ctx.log 'Check who manage /etc/krb5.conf'
  return next null if ctx.hasAction 'histi/actions/krb5_server'
  @name 'Kerberos client # Configure'
  {etc_krb5_conf} = ctx.config.krb5_client
  ctx.log 'Update /etc/krb5.conf'
  ctx.ini
    content: etc_krb5_conf
    destination: '/etc/krb5.conf'
    stringify: misc.ini.stringify_square_then_curly
  , (err, written) ->
    return next err, if written then ctx.OK else ctx.PASS

###
Create host principal
---------------------

Note, I have experienced random situations where next was called multiple times.
###
module.exports.push (ctx, next) ->
  @name 'Kerberos client # Create host principal'
  @timeout 100000
  {realm, kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5_client
  # quit = false
  ctx.log 'Create an admin user principal and assign a password to this new user'
  mkprincipal
    ssh: ctx.ssh
    log: ctx.log
    stdout: ctx.log.out
    stderr: ctx.log.err
    principal: "host/#{ctx.config.host}@#{realm}"
    randkey: true
    kadmin_principal: kadmin_principal
    kadmin_password: kadmin_password
    admin_server: admin_server
  , (err, created) ->
    return next err if err
    modified = true if created
    next null, if modified then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'Kerberos client # Configure SSHD'
  @timeout -1
  {sshd} = ctx.config.krb5_client
  return next null, ctx.DISABLED unless sshd
  write = []
  for k, v of sshd
    write.push
      match: new RegExp "^#{k}.*$", 'mg'
      replace: "#{k} #{v}"
      append: true
  ctx.log 'Write /etc/ssh/sshd_config'
  ctx.write
    write: write
    destination: '/etc/ssh/sshd_config'
  , (err, written) ->
    return next err if err
    return next null, ctx.PASS unless written
    ctx.log 'Restart openssh'
    ctx.service
      name: 'openssh'
      srv_name: 'sshd'
      action: 'restart'
    , (err, restarted) ->
      next err, ctx.OK

