
## Configuration

Pig uses the "hdfs" configuration. It also declare 2 optional properties:

*   `hdp.force_check` (string)
    Force the execution of the check action on each run, otherwise it will
    run only on the first install. The property is shared by multiple
    modules and default to false.
*   `pig.user` (object|string)
    The Unix Pig login name or a user object (see Nikita User documentation).
*   `hdp.pig.conf_dir` (string)
    The Pig configuration directory, dont overwrite, default to "/etc/pig/conf".

Example:

```json
{
  "ryba": {
    "pig": {
      "config": {
        "pig.cachedbag.memusage": "0.1",
        "pig.skewedjoin.reduce.memusage", "0.3"
      }
    },
    force_check: true
  }
}
```

    module.exports = (service) ->
      options = service.options

## Identities

      # Group
      options.group ?= {}
      options.group = name: options.group if typeof options.group is 'string'
      options.group.name ?= 'pig'
      options.group.system ?= true
      # User
      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.name ?= 'pig'
      options.user.system ?= true
      options.user.gid ?= 'pig'
      options.user.comment ?= 'Pig User'
      options.user.home ?= '/var/lib/pig'

## Kerberos

      # Kerberos Test Principal
      options.test_krb5_user ?= service.deps.test_user.options.krb5.user

## Environment

      # Layout
      options.conf_dir ?= '/etc/pig/conf'
      # Java
      options.java_home ?= service.deps.java.options.java_home
      # Misc
      options.hostname ?= service.node.hostname

## Configuration

      options.config ?= {}

## Test

      options.test = merge {}, service.deps.test_user.options, options.test

## Wait

      options.wait_yarn_rm = service.deps.yarn_rm[0].options.wait
      options.wait_hive_hcatalog = service.deps.hive_client.options.wait_hive_hcatalog

## Dependencies

    {merge} = require 'nikita/lib/misc'
