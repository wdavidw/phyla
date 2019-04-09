
# Shinken Configure

*   `options.user` (object|string)
    The Unix Shinken login name or a user object (see Nikita User documentation).
*   `options.group` (object|string)
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

    module.exports = (service) ->
      options = service.options
      # throw Error 'Cannot install Shinken: no scheduler provided' unless @contexts('@rybajs/metal/shinken/scheduler').length
      # throw Error 'Cannot install Shinken: no poller provided' unless @contexts('@rybajs/metal/shinken/poller').length
      # throw Error 'Cannot install Shinken: no receiver provided' unless @contexts('@rybajs/metal/shinken/receiver').length
      # throw Error 'Cannot install Shinken: no reactionner provided' unless @contexts('@rybajs/metal/shinken/reactionner').length
      # throw Error 'Cannot install Shinken: no broker provided' unless @contexts('@rybajs/metal/shinken/broker').length
      # throw Error 'Cannot install Shinken: no arbiter provided' unless @contexts('@rybajs/metal/shinken/arbiter').length
      options.build_dir ?= '/var/tmp/@rybajs/metal/shinken'
      options.pid_dir ?= '/var/run/shinken'
      options.log_dir ?= '/var/log/shinken'
      options.plugin_dir ?= '/usr/lib64/nagios/plugins'
      options.python_modules ?= {}
      options.python_modules.CherryPy ?= {}
      options.python_modules.CherryPy.version ?= '11.0.0'
      options.python_modules.CherryPy.url ?= 'https://pypi.python.org/packages/bf/2b/febc9a1f09bf9249b0ce1723d06dbedd9ff34879b76d17180611c48a7f63/CherryPy-11.0.0.tar.gz#md5=3caf903447ed39057466256fa9c69554'
      options.python_modules.pycparser ?= {}
      options.python_modules.pycparser.version ?= '2.18'
      options.python_modules.pycparser.url ?= 'https://pypi.python.org/packages/8c/2d/aad7f16146f4197a11f8e91fb81df177adcc2073d36a17b1491fd09df6ed/pycparser-2.18.tar.gz#md5=72370da54358202a60130e223d488136'
      options.python_modules.asn1crypto ?= {}
      options.python_modules.asn1crypto.version ?= '0.22.0'
      options.python_modules.asn1crypto.url ?= 'https://pypi.python.org/packages/67/14/5d66588868c4304f804ebaff9397255f6ec5559e46724c2496e0f26e68d6/asn1crypto-0.22.0.tar.gz#md5=74a8b9402625b38ef19cf3fa69ef8470'
      options.python_modules.cffi ?= {}
      options.python_modules.cffi.version ?= '1.10.0'
      options.python_modules.cffi.url ?= 'https://pypi.python.org/packages/5b/b9/790f8eafcdab455bcd3bd908161f802c9ce5adbf702a83aa7712fcc345b7/cffi-1.10.0.tar.gz#md5=2b5fa41182ed0edaf929a789e602a070'
      options.python_modules.enum34 ?= {}
      options.python_modules.enum34.version ?= '1.1.6'
      options.python_modules.enum34.url ?= 'https://pypi.python.org/packages/bf/3e/31d502c25302814a7c2f1d3959d2a3b3f78e509002ba91aea64993936876/enum34-1.1.6.tar.gz#md5=5f13a0841a61f7fc295c514490d120d0'
      options.python_modules.idna ?= {}
      options.python_modules.idna.version ?= '2.5'
      options.python_modules.idna.url ?= 'https://pypi.python.org/packages/d8/82/28a51052215014efc07feac7330ed758702fc0581347098a81699b5281cb/idna-2.5.tar.gz#md5=fc1d992bef73e8824db411bb5d21f012'
      options.python_modules.ipaddress ?= {}
      options.python_modules.ipaddress.version ?= '1.0.18'
      options.python_modules.ipaddress.url ?= 'https://pypi.python.org/packages/4e/13/774faf38b445d0b3a844b65747175b2e0500164b7c28d78e34987a5bfe06/ipaddress-1.0.18.tar.gz#md5=310c2dfd64eb6f0df44aa8c59f2334a7'
      options.python_modules.six ?= {}
      options.python_modules.six.version ?= '1.10.0'
      options.python_modules.six.url ?= 'https://pypi.python.org/packages/b3/b2/238e2590826bfdd113244a40d9d3eb26918bd798fc187e2360a8367068db/six-1.10.0.tar.gz#md5=34eed507548117b2ab523ab14b2f8b55'
      options.python_modules.cryptography ?= {}
      options.python_modules.cryptography.version ?= '1.9'
      options.python_modules.cryptography.url ?= 'https://pypi.python.org/packages/2a/0c/31bd69469e90035381f0197b48bf71032991d9f07a7e444c311b4a23a3df/cryptography-1.9.tar.gz#md5=1529f12fb403c9a0045277cb73df766c'
      options.python_modules.pyOpenSSL ?= {}
      options.python_modules.pyOpenSSL.version ?= '17.1.0'
      options.python_modules.pyOpenSSL.url ?= 'https://pypi.python.org/packages/4b/13/5521fdbfe26e0aa4aa04b9133c0dd5450a50e4aee5be44461d448e57560e/pyOpenSSL-17.1.0.tar.gz#md5=19fcc38b77fc17f494f671c8ae04b40f'
      for pyname, pymod of options.python_modules
        pymod.format ?= 'tar.gz'
        pymod.archive ?= "#{pyname}-#{pymod.version}"
        pymod.url ?= "https://pypi.python.org/simple/#{pyname}/#{pymod.archive}.#{pymod.format}"
      # Misc
      options.prepare = service.deps.commons[0].node.fqdn is service.node.fqdn

## Identities

      #user
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'nagios'
      options.user.system ?= true
      options.user.comment ?= 'Nagios/Shinken User'
      options.user.home ?= '/var/lib/shinken'
      options.user.shell ?= '/bin/bash'
      #group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'nagios'
      options.group.system ?= true
      options.user.gid = options.group.name

## Commons Config

      options.config ?= {}
      options.config['date_format'] ?= 'iso8601'
      options.config['shinken_user'] ?= options.user.name
      options.config['shinken_group'] ?= options.group.name
      options.config['interval_length'] ?= '1'
      options.config['enable_flap_detection'] ?= '1'
      options.config['no_event_handlers_during_downtimes'] ?= '1'

## SSL

      options.ssl = merge service.deps.ssl?.options, options.ssl
      options.ssl.enabled ?= !!service.deps.ssl
      if options.ssl.enabled
        options.config['use_ssl'] ?= '1'
        options.config['hard_ssl_name_check'] ?= '1'
        throw Error 'Missing options.ssl.cacert' unless options.ssl.cacert
        throw Error 'Missing options.ssl.cert' unless options.ssl.cert
        throw Error 'Missing options.ssl.key' unless options.ssl.key
        options.config['ca_cert'] ?= '/etc/shinken/certs/ca.pem'
        options.config['server_cert'] ?= '/etc/shinken/certs/cert.pem'
        options.config['server_key'] ?= '/etc/shinken/certs/key.pem'
      else
        options.config['use_ssl'] ?= '0'
        options.config['hard_ssl_name_check'] ?= '0'

## Commons ini

      options.ini ?= {}
      # Hard values
      options.ini.logdir = options.log_dir
      options.ini.workdir = options.pid_dir
      options.ini.user = options.config['shinken_user']
      options.ini.group = options.config['shinken_group']
      options.ini.use_ssl = options.config['use_ssl']
      options.ini.ca_cert = options.config['ca_cert']
      options.ini.server_cert = options.config['server_cert']
      options.ini.server_key = options.config['server_key']
      options.ini.hard_ssl_name_check = options.config['hard_ssl_name_check']
      # Configurable values
      options.ini.daemon_enabled ?= '1'
      options.ini.http_backend ?= 'auto'
      options.ini.log_level ?= 'WARNING'
      options.ini.use_local_log ?= '1'
      options.ini.modules_dir ?= '/var/lib/shinken/modules'

## Dependencies

    {merge} = require 'mixme'
