
## Configuration

The module extends the "@rybajs/metal/hadoop/core" module configuration.

*   `libs`, (array, string)
    List jar files (usually JDBC drivers) to upload into the Sqoop lib path.
    Use the space or comma charectere to separate the paths when the value is a
    string. This is for example used to add the Oracle JDBC driver "ojdbc6.jar"
    which cannt be downloaded for licensing reasons.
*   `user` (object|string)
    The Unix Sqoop login name or a user object (see Nikita User documentation).

Todo, with oozie, it seems like drivers must be stored in "/user/oozie/share/lib/sqoop".

Example:

```json
{
  "user": {
    "name": "sqoop", "system": true, "gid": "hadoop",
    "comment": "Sqoop User", "home": "/var/lib/sqoop"
  },
  "libs": "./path/to/ojdbc6.jar"
}
```

    module.exports = (service) ->
      {options} = service

## Identities

      # Group
      options.group ?= {}
      options.group = name: options.group if typeof options.group is 'string'
      options.group.name ?= 'sqoop'
      options.group.system ?= true
      # User
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'sqoop'
      options.user.system ?= true
      options.user.comment ?= 'Sqoop User'
      options.user.gid ?= options.group.name
      options.user.home ?= '/var/lib/sqoop'

## Environment

      # Layout
      options.conf_dir ?= '/etc/sqoop/conf'

## Configuration

      options.sqoop_site ?= {}
      # Libs
      options.libs ?= []
      options.libs = options.libs.split /[\s,]+/ if typeof options.libs is 'string'
