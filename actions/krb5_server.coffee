
###
Kerberos KDC with OpenLDAP Back-End
===================================

Usefull commands:
*   To list all the current principals in the realm: `getprincs`
*   To login: `kadmin -p big/admin@EDF.FR -s big1.big`
*   To print details on a principal: `getprinc host/hadoop1.hadoop@ADALTAS.COM`
*   To examine the content of the /etc/krb5.keytab: `klist -etk /etc/krb5.keytab`
*   To destroy our own tickets: `kdestroy`
*   To get the test.user's ticket: `kinit -p wdavidw@ADALTAS.COM`
*   To confirm that we do indeed have the new ticket: `klist`
*   Check krb5kdc is listening: `netstat -nap | grep :750\\b` and `netstat -nap | grep :88\\b`

Resources:
*   [Kerberos with LDAP backend on centos](http://itdavid.blogspot.fr/2012/05/howto-centos-62-kerberos-kdc-with.html)
*   [Propagation](http://www-old.grantcohoe.com/guides/services/krb5-kdc)
*   [Kerberos with LDAP backend on ubuntu](http://labs.opinsys.com/blog/2010/02/05/setting-up-openldap-kerberos-on-ubuntu-10-04-lucid/)

###
mecano = require 'mecano'
each = require 'each'
misc = require 'mecano/lib/misc'
mkprincipal = require './krb5/lib/mkprincipal'
module.exports = []

module.exports.push 'histi/actions/yum'

module.exports.push module.exports.configure = (ctx) ->
  ctx.config.krb5_server ?= {}
  throw new Error "Kerberos property realm is required" unless ctx.config.krb5_server.realm
  throw new Error "Kerberos property ldap_kerberos_container_dn is required" unless ctx.config.krb5_server.ldap_kerberos_container_dn
  throw new Error "Kerberos property ldap_kdc_dn is required" unless ctx.config.krb5_server.ldap_kdc_dn
  throw new Error "Kerberos property ldap_kadmind_dn is required" unless ctx.config.krb5_server.ldap_kadmind_dn
  ctx.config.krb5_server.realm = ctx.config.krb5_server.realm.toUpperCase()
  {realm, ldap_kerberos_container_dn, ldap_kdc_dn, ldap_kadmind_dn, ldap_servers} = ctx.config.krb5_server
  ldap_servers = [ldap_servers] if typeof ldap_servers is 'string'
  REALM = realm
  realm = REALM.toLowerCase()
  unless ctx.config.krb5_server.etc_krb5_conf
    etc_krb5_conf =
      'logging':
        'default': 'SYSLOG:INFO:LOCAL1'
        'kdc': 'SYSLOG:NOTICE:LOCAL1'
        'admin_server': 'SYSLOG:WARNING:LOCAL1'
      'libdefaults': 
        'default_realm': "#{REALM}"
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
      'dbmodules':
        'openldap_ldapconf':
          'db_library': 'kldap'
          'ldap_kerberos_container_dn': ldap_kerberos_container_dn
          'ldap_kdc_dn': ldap_kdc_dn
           # this object needs to have read rights on
           # the realm container, principal container and realm sub-trees
          'ldap_kadmind_dn': ldap_kadmind_dn
           # this object needs to have read and write rights on
           # the realm container, principal container and realm sub-trees
          'ldap_service_password_file': '/etc/krb5.d/stash.keyfile'
          # 'ldap_servers': 'ldapi:///'
          'ldap_servers': ldap_servers.join ' '
          'ldap_conns_per_server': 5
    etc_krb5_conf.realms["#{REALM}"] = 
      'kdc': ctx.config.krb5_server.kdc or realm
      'admin_server': ctx.config.krb5_server.admin_server or realm
      'default_domain': ctx.config.krb5_server.default_domain or realm
      'database_module': 'openldap_ldapconf'
    etc_krb5_conf.domain_realm[".#{realm}"] = REALM
    etc_krb5_conf.domain_realm["#{realm}"] = REALM
    ctx.config.krb5_server.etc_krb5_conf = etc_krb5_conf
  unless ctx.config.krb5_server.kdc_conf
    kdc_conf =
      'kdcdefaults':
        'kdc_ports': 88
        'kdc_tcp_ports': 88
      'realms': {}
      'logging':
          'kdc': 'FILE:/tmp/kdc.log'
    kdc_conf.realms[REALM] = 
      '#master_key_type': 'aes256-cts'
      'acl_file': '/var/kerberos/krb5kdc/kadm5.acl'
      'dict_file': '/usr/share/dict/words'
      'admin_keytab': '/var/kerberos/krb5kdc/kadm5.keytab'
      'supported_enctypes': 'aes256-cts:normal aes128-cts:normal des3-hmac-sha1:normal arcfour-hmac:normal des-hmac-sha1:normal des-cbc-md5:normal des-cbc-crc:normal'
    ctx.config.krb5_server.kdc_conf = kdc_conf

module.exports.push (ctx, next) ->
  @name 'KRB5 Server (LDAP) # Install'
  ctx.service
    name: 'krb5-server-ldap'
  , (err, installed) ->
    next err, if installed then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'KRB5 Server (LDAP) # Insert entries'
  @timeout 100000
  {realm, etc_krb5_conf, kdc} = ctx.config.krb5_server
  {manager_dn, manager_password, realms_dn} = ctx.config.openldap_krb5
  # Note, kdb5_ldap_util is using /etc/krb5.conf (server version)
  ctx.log 'Update /etc/krb5.conf'
  ctx.ini
    content: etc_krb5_conf
    destination: '/etc/krb5.conf'
    stringify: misc.ini.stringify_square_then_curly
    backup: true
  , (err, written) ->
    ctx.log 'Run kdb5_ldap_util'
    # Without "-P", it prompts for the KDC database master key
    kdc_master_key = 'test'
    cmd = "kdb5_ldap_util -D \"#{manager_dn}\" -w #{manager_password} create -subtrees \"#{realms_dn}\" -r #{realm} -s -P #{kdc_master_key}"
    ctx.log "Execute: #{cmd}"
    ctx.execute
      cmd: cmd
      code_skipped: 1
    , (err, executed, stdout, stderr) ->
      # Warnig, exit code 1 for also for connect error
      next err, if executed then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'KRB5 Server (LDAP) # Stash password'
  keyfileContent = null
  read = ->
    ctx.log 'Read current keyfile if it exists'
    misc.file.readFile ctx.ssh, '/etc/krb5.d/stash.keyfile', 'utf8', (err, content) ->
      return mkdir() if err and err.code is 'ENOENT'
      return next err if err
      keyfileContent = content
      stash()
  mkdir = ->
    ctx.log 'Create directory "/etc/krb5.d"'
    ctx.mkdir '/etc/krb5.d', (err, created) ->
      return next err if err
      stash()
  stash = ->
    ctx.log 'Stash password into local file'
    {ldap_kadmind_dn} = ctx.config.krb5_server
    {manager_dn, manager_password} = ctx.config.openldap_krb5
    ctx.ssh.shell (err, stream) ->
      return next err if err
      # kdb5_ldap_util -D "cn=Manager,dc=adaltas,dc=com" -w test stashsrvpw -f /etc/krb5.d/stash.keyfile cn=krbadmin,ou=users,dc=adaltas,dc=com
      cmd = "kdb5_ldap_util -D \"#{manager_dn}\" -w #{manager_password} stashsrvpw -f /etc/krb5.d/stash.keyfile #{ldap_kadmind_dn}"
      ctx.log "Run #{cmd}"
      stream.write "#{cmd}\n"
      stream.on 'data', (data) ->
        ctx.log.out.write data
        data = data.toString()
        reentered = false
        if /Password for/.test data
          stream.write 'test\n'
        if /Re-enter password for/.test data
          stream.write 'test\n'
          reentered = true
        if reentered and /\r\n/.test data
          return next null, ctx.OK unless keyfileContent
          stream.end()
      stream.on 'close', ->
        compare()
  compare = ->
    misc.file.readFile ctx.ssh, '/etc/krb5.d/stash.keyfile', 'utf8', (err, content) ->
      next err, if keyfileContent is content then ctx.PASS else ctx.OK
  read()

module.exports.push (ctx, next) ->
  @name 'KRB5 Server # Install'
  @timeout -1
  ctx.log 'Install krb5kdc and kadmin services'
  ctx.service [
    name: 'krb5-pkinit-openssl'
  ,
    name: 'krb5-server-ldap'
    startup: true
    chk_name: 'krb5kdc'
    srv_name: 'krb5kdc'
  ,
    name: 'krb5-server-ldap'
    startup: true
    chk_name: 'kadmin'
    srv_name: 'kadmin'
  ,
    name: 'words'
  ,
    name: 'krb5-workstation'
  ], (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'KRB5 Server # Configure'
  @timeout 100000
  {realm, etc_krb5_conf, kdc_conf} = ctx.config.krb5_server
  modified = false
  exists = false
  chkexists = ->
    misc.file.exists ctx.ssh, '/etc/krb5.conf', (err, e) ->
      exists = e
  do_krb5 = ->
    ctx.log 'Update /etc/krb5.conf'
    ctx.ini
      content: etc_krb5_conf
      destination: '/etc/krb5.conf'
      stringify: misc.ini.stringify_square_then_curly
      backup: true
    , (err, written) ->
      return next err if err
      modified = true if written
      do_kadm5()
  do_kadm5 = ->
    ctx.log 'Update /var/kerberos/krb5kdc/kadm5.acl'
    ctx.write
      match: /^\*\/\w+@[\w\.]+\s+\*/mg
      replace: "*/admin@#{realm}     *"
      destination: '/var/kerberos/krb5kdc/kadm5.acl'
      backup: true
    , (err, written) ->
      return next err if err
      modified = true if written
      do_kdc()
  do_kdc = ->
    ctx.log 'Update /var/kerberos/krb5kdc/kdc.conf'
    ctx.ini
      content: kdc_conf
      destination: '/var/kerberos/krb5kdc/kdc.conf'
      stringify: misc.ini.stringify_square_then_curly
      backup: true
    , (err, written) ->
      return next err if err
      modified = true if written
      do_end()
  do_end = (err) ->
    return next err if err
    return next null, ctx.PASS unless modified
    # The first time, we dont restart because ldap conf is 
    # not there yet
    return next null, ctx.OK unless exists
    ctx.log '(Re)start krb5kdc and kadmin services'
    ctx.service [
      name: 'krb5-server'
      action: 'restart'
      srv_name: 'krb5kdc'
    ,
      name: 'krb5-server'
      action: 'restart'
      srv_name: 'kadmin'
    ], (err, serviced) ->
      next err, ctx.OK
  do_krb5()

module.exports.push (ctx, next) ->
  @name 'KRB5 Server # Log'
  @timeout 100000
  modified = false
  touch = ->
    ctx.log 'Touch "/etc/logrotate.d/krb5kdc" and "/etc/logrotate.d/kadmind"'
    ctx.write [
      content: ''
      destination: '/var/log/krb5kdc.log'
      not_if_exists: true
    ,
      content: ''
      destination: '/var/log/kadmind.log'
      not_if_exists: true
    ], (err, written) ->
      return done err if err
      modified = true if written
      rsyslog()
  rsyslog = ->
    ctx.log 'Update /etc/rsyslog.conf'
    ctx.write
      destination: '/etc/rsyslog.conf'
      write: [
        match: /.*krb5kdc.*/mg
        replace: 'if $programname == \'krb5kdc\' then /var/log/krb5kdc.log'
        append: '### RULES ###'
      ,
        match: /.*kadmind.*/mg
        replace: 'if $programname == \'kadmind\' then /var/log/kadmind.log'
        append: '### RULES ###'
      ]
    , (err, written) ->
      return done err if err
      modified = true if written
      if written then restart() else done()
  restart = ->
    ctx.log 'Restart krb5kdc and kadmin'
    ctx.service [
      name: 'krb5-server'
      action: 'start'
      srv_name: 'krb5kdc'
    ,
      name: 'krb5-server'
      action: 'start'
      srv_name: 'kadmin'
    ], (err, restarted) ->
      return done err if err
      ctx.log 'Restart rsyslog'
      ctx.service
        name: 'rsyslog'
        action: 'restart'
      , (err, restarted) ->
        done err
  done = (err) ->
    next err, if modified then ctx.OK else ctx.PASS
  touch()

module.exports.push (ctx, next) ->
  @name 'KRB5 Server # Admin principal'
  @timeout -1
  {kadmin_principal, kadmin_password} = ctx.config.krb5_server
  ctx.log "Create principal #{kadmin_principal}"
  mkprincipal
    # We dont provide an "admin_server". Instead, we need
    # to use "kadmin.local" because the principal used
    # to login with "kadmin" isnt created yet
    ssh: ctx.ssh
    log: ctx.log
    stdout: ctx.log.out
    stderr: ctx.log.err
    principal: kadmin_principal
    password: kadmin_password
  , (err, created) ->
    next err, if created then ctx.OK else ctx.PASS

module.exports.push (ctx, next) ->
  @name 'KRB5 Server # Start'
  @timeout 100000
  ctx.service [
    name: 'krb5-server-ldap'
    action: 'start'
    srv_name: 'krb5kdc'
  ,
    name: 'krb5-server-ldap'
    action: 'start'
    srv_name: 'kadmin'
  ], (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS

###
Populate
--------
Populate DB with machines and users principals.
###
module.exports.push (ctx, next) ->
  @name 'KRB5 Server # Populate'
  {realm, principals, kadmin_principal, kadmin_password, admin_server} = ctx.config.krb5_server
  modified = false
  createMachinePrincipal = ->
    ctx.log "Create principal host/#{ctx.config.host}@#{realm}"
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
      createConfigPrincipals()
  createConfigPrincipals = ->
    each(principals)
    .on 'item', (principal, next) ->
      ctx.log "Create principal host/#{ctx.config.host}@#{realm}"
      options = 
        ssh: ctx.ssh
        log: ctx.log
        stdout: ctx.log.out
        stderr: ctx.log.err
        kadmin_principal: kadmin_principal
        kadmin_password: kadmin_password
        admin_server: admin_server
      for k, v of principal then options[k] = v
      mkprincipal options, (err, created) ->
        return next err if err
        modified = true if created
        next()
    .on 'both', (err) ->
      done err
  done = (err) ->
    next err, if modified then ctx.OK else ctx.PASS
  createMachinePrincipal()







