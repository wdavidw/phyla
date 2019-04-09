
# Hortonworks Smartsense Server Configuration

    module.exports = (service) ->
      options = service.options

## Identities

      # Group
      options.group ?= {}
      options.group = name: options.group if typeof options.group is 'string'
      options.group.name ?= 'smartsense'
      options.group.system ?= true
      # User & Group
      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.name ?= 'smartsense'
      options.user.gid ?= options.group.name
      options.user.system ?= true
      options.user.comment ?= 'Hortonworks SmartSense User'
      options.user.home ?= '/var/lib/smartsense'
      options.user.groups ?= 'hadoop'

## Environment

      options.conf_dir ?= '/etc/hst/conf'
      options.tmp_dir ?= '/tmp'
      options.pid_dir ?= '/var/run/hst'
      options.log_dir ?= '/var/log/hst'
      options.ssl_pass ?= 'DEV'

## Source
Note: Can not specify default source, as the rpm need to be downloaded by administrator
from https://support.hortonworks.com site

      options.source ?= null

## SSL

      options.ssl = merge service.use.ssl?.options, options.ssl
      options.ssl.enabled = !!service.use.ssl
      if options.ssl.enabled
        throw Error "Required Option: ssl.cert" if  not options.ssl.cert
        throw Error "Required Option: ssl.key" if not options.ssl.key
        throw Error "Required Option: ssl.cacert" if not options.ssl.cacert
        
## Configuration
      
      # Misc
      options.fqdn ?= service.node.fqdn
      options.hostname = service.node.hostname
      options.iptables ?= service.use.iptables and service.use.iptables.options.action is 'start'
      options.clean_logs ?= false
      options.ini ?= {}
      options.ini['server'] ?= {}
      options.ini['server']['port'] ?= 9000
      options.ini['server']['ssl_enabled'] ?= true # for now does not work with ssl_enabled option
      options.ini['server']['tmp.dir'] ?= '/var/lib/smartsense/hst-server/tmp'
      options.ini['server']['storage.dir'] ?= '/var/lib/smartsense/hst-server/data'
      options.ini['server']['run.as.user'] ?= options.user.name
      options.ini['client'] ?= {}
      options.ini['client']['password_less_ssh.enabled'] ?= false
      options.ini['cluster'] ?= {}
      options.ini['cluster']['name'] ?= 'ryba-cluster'
      options.ini['cluster']['secured'] ?= if @config.ryba.security is 'kerberos' then true else false
      options.ini['customer'] ?= {}
      options.ini['customer']['account.name'] ?= 'ryba'
      options.ini['customer']['notification.email'] ?= 'ryba@ryba.io'
      options.ini['customer']['options.id'] ?= 'A-00000000-C-00000000'
      options.ini['java'] ?= {}
      options.ini['java']['home'] ?= service.use.java.java_home
      options.ini['security'] ?= {}
      options.ini['security']['options.keys_dir'] ?= "#{options.user.home}/hst-server/keys"
      options.ini['security']['options.one_way_ssl.port'] ?= 9440
      options.ini['security']['options.two_way_ssl.port'] ?= 9441
      options.ini['security']['options.keys_dir'] ?= "#{options.user.home}/hst-server/keys"
      options.ini['security']['anonymization.shared.key'] ?= "#{options.user.home}/hst-common/anonymization/keys/shared_anonymization.key"
      options.ini['security']['anonymization.private.key'] ?= "#{options.user.home}/hst-common/anonymization/keys/private_anonymization.key"
      options.ini['security']['encryption.public.key'] ?= "#{options.user.home}/hst-common/encryption/keys/public.key"
      options.ini['security']['encryption.file.size.method'] ?= 'NO_SIZE'
      options.ini['security']['encryption.file.size.buffer'] ?= 1536

## Wait

      options.wait_local =
        host: service.node.fqdn
        port: options.ini['server']['port']
      options.wait_local_ssl_one_way =
        host: service.node.fqdn
        port: options.ini['security']['options.one_way_ssl.port']
      options.wait_local_ssl_two_way =
        host: service.node.fqdn
        port: options.ini['security']['options.two_way_ssl.port']

## Dependencies

    {merge} = require 'mixme'
