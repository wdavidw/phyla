
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

## Commons ini

      shinken.ini ?= {}
      shinken.ini.logdir = shinken.log_dir
      shinken.ini.workdir = shinken.pid_dir
      shinken.ini.user = shinken.user.name
      shinken.ini.group = shinken.group.name
      shinken.ini.use_local_log ?= '1'
      shinken.ini.log_level ?= 'WARNING'
      shinken.ini.http_backend ?= 'auto'
      shinken.ini.daemon_enabled ?= '1'
      shinken.ini.modules_dir ?= '/var/lib/shinken/modules'
