
# Ambari Ranger Admin Configure

    module.exports = ({deps, options}) ->

## Identities

      # Group
      options.group ?= {}
      options.group = name: options.group if typeof options.group is 'string'
      options.group.name ?= 'ranger'
      options.group.system ?= true
      # User
      options.user ?= {}
      options.user = name: options.user if typeof options.user is 'string'
      options.user.name ?= 'ranger'
      options.user.system ?= true
      options.user.comment ?= 'Ranger User'
      options.user.home ?= "/var/lib/#{options.user.name}"
      options.user.gid ?= options.group.name
      options.user.groups ?= 'hadoop'
