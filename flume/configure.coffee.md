
## Configure

*   `user` (object|string)
    The Unix Flume login name or a user object (see Nikita User
    documentation).
*   `group` (object|string)
    The Unix Flume group name or a group object (see Nikita Group
    documentation).

Example:

```json
{
  "ryba": {
    "flume": {
      "user": {
        "name": "flume", "system": true, "gid": "flume",
        "comment": "Flume User", "home": "/var/lib/flume"
      },
      "group": {
        "name": "flume", "system": true
      },
      "conf_dir": "/etc/flume/conf"
    }
  }
}
```

    module.exports = ->
      service = migration.call @, service, 'ryba/flume', ['ryba', 'flume'], require('nikita/lib/misc').merge require('.').use,
        krb5_client: key: ['krb5_client']
        hadoop_core: key: ['ryba']
      @config.ryba ?= {}
      @config.ryba.oozie ?= {}
      options = @config.ryba.flume = service.options

## Environment

      options.conf_dir = '/etc/flume/conf'

## Identities

      # Group
      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'flume'
      options.group.system ?= true
      # User
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'flume'
      options.user.system ?= true
      options.user.gid ?= options.group.name
      options.user.comment ?= 'Flume User'
      options.user.home ?= '/var/lib/flume'

## Kerberos

      # Administration
      options.krb5 ?= {}
      options.krb5.realm ?= service.use.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      options.krb5.admin ?= service.use.krb5_client.options.admin[options.krb5.realm]
      # Flume Principal
      options.krb5_user ?= {}
      options.krb5_user.principal ?= "#{options.user.name}/#{service.use.fqdn}@#{options.krb5.realm}"
      options.krb5_user.keytab ?= "#{options.conf_dir}/flume.service.keytab"
      options.krb5_user.randkey ?= true

## Dependencies

    migration = require 'masson/lib/migration'
