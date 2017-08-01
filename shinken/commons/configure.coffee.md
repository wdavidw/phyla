
# Shinken Configure

*   `shinken.user` (object|string)   
    The Unix Shinken login name or a user object (see Nikita User documentation).   
*   `shinken.group` (object|string)   
    The Unix Shinken group name or a group object (see Nikita Group documentation).   

Example

```json
    "shinken":{
      "user": {
        "name": "shinken", "system": true, "gid": "shinken",
        "comment": "Shinken User"
      },
      "group": {
        "name": "shinken", "system": true
      }
    }
```

    module.exports = ->
      {ssl} = @config
      shinken = @config.ryba.shinken ?= {}
      throw Error 'Cannot install Shinken: no scheduler provided' unless @contexts('ryba/shinken/scheduler').length
      throw Error 'Cannot install Shinken: no poller provided' unless @contexts('ryba/shinken/poller').length
      throw Error 'Cannot install Shinken: no receiver provided' unless @contexts('ryba/shinken/receiver').length
      throw Error 'Cannot install Shinken: no reactionner provided' unless @contexts('ryba/shinken/reactionner').length
      throw Error 'Cannot install Shinken: no broker provided' unless @contexts('ryba/shinken/broker').length
      throw Error 'Cannot install Shinken: no arbiter provided' unless @contexts('ryba/shinken/arbiter').length
      shinken.build_dir ?= '/var/tmp/ryba/shinken'
      shinken.pid_dir ?= '/var/run/shinken'
      shinken.log_dir ?= '/var/log/shinken'
      shinken.plugin_dir ?= '/usr/lib64/nagios/plugins'
      shinken.python_modules ?= {}
      shinken.python_modules.CherryPy ?= {}
      shinken.python_modules.CherryPy.version ?= '11.0.0'
      shinken.python_modules.pycparser ?= {}
      shinken.python_modules.pycparser.version ?= '2.18'
      shinken.python_modules.asn1crypto ?= {}
      shinken.python_modules.asn1crypto.version ?= '0.22.0'
      shinken.python_modules.cffi ?= {}
      shinken.python_modules.cffi.version ?= '1.10.0'
      shinken.python_modules.enum34 ?= {}
      shinken.python_modules.enum34.version ?= '1.1.6'
      shinken.python_modules.idna ?= {}
      shinken.python_modules.idna.version ?= '2.5'
      shinken.python_modules.ipaddress ?= {}
      shinken.python_modules.ipaddress.version ?= '1.0.18'
      shinken.python_modules.six ?= {}
      shinken.python_modules.six.version ?= '1.10.0'
      shinken.python_modules.cryptography ?= {}
      shinken.python_modules.cryptography.version ?= '1.9'
      shinken.python_modules.pyOpenSSL ?= {}
      shinken.python_modules.pyOpenSSL.version ?= '17.1.0'
      for pyname, pymod of shinken.python_modules
        pymod.format ?= 'tar.gz'
        pymod.archive ?= "#{pyname}-#{pymod.version}"
        pymod.url ?= "https://pypi.python.org/simple/#{pyname}/#{pymod.archive}.#{pymod.format}"

## User

      shinken.user = name: shinken.user if typeof shinken.user is 'string'
      shinken.user ?= {}
      shinken.user.name ?= 'nagios'
      shinken.user.system ?= true
      shinken.user.comment ?= 'Nagios/Shinken User'
      shinken.user.home ?= '/var/lib/shinken'
      shinken.user.shell ?= '/bin/bash'

## Group

      shinken.group = name: shinken.group if typeof shinken.group is 'string'
      shinken.group ?= {}
      shinken.group.name ?= 'nagios'
      shinken.group.system ?= true
      shinken.user.gid = shinken.group.name

## Commons Config

      shinken.config ?= {}
      shinken.config['date_format'] ?= 'iso8601'
      shinken.config['shinken_user'] ?= shinken.user.name
      shinken.config['shinken_group'] ?= shinken.group.name
      shinken.config['interval_length'] ?= '1'
      shinken.config['enable_flap_detection'] ?= '1'
      shinken.config['no_event_handlers_during_downtimes'] ?= '1'
      if ssl
        shinken.config['use_ssl'] ?= '1'
        shinken.config['hard_ssl_name_check'] ?= '1'
      else
        shinken.config['use_ssl'] ?= '0'
        shinken.config['hard_ssl_name_check'] ?= '0'
      shinken.config['ca_cert'] ?= '/etc/shinken/certs/ca.pem'
      shinken.config['server_cert'] ?= '/etc/shinken/certs/cert.pem'
      shinken.config['server_key'] ?= '/etc/shinken/certs/key.pem'

## Commons ini

      shinken.ini ?= {}
      # Hard values
      shinken.ini.logdir = shinken.log_dir
      shinken.ini.workdir = shinken.pid_dir
      shinken.ini.user = shinken.config['shinken_user']
      shinken.ini.group = shinken.config['shinken_group']
      shinken.ini.use_ssl = shinken.config['use_ssl']
      shinken.ini.ca_cert = shinken.config['ca_cert']
      shinken.ini.server_cert = shinken.config['server_cert']
      shinken.ini.server_key = shinken.config['server_key']
      shinken.ini.hard_ssl_name_check = shinken.config['hard_ssl_name_check']
      # Configurable values
      shinken.ini.daemon_enabled ?= '1'
      shinken.ini.http_backend ?= 'auto'
      shinken.ini.log_level ?= 'WARNING'
      shinken.ini.use_local_log ?= '1'
      shinken.ini.modules_dir ?= '/var/lib/shinken/modules'
