
# Node.js Configure

*   `nodejs.version` (string)   
    Any NodeJs version with the addition of "latest" and "stable", see the [N] 
    documentation for more information, default to "stable".
*   `nodejs.merge` (boolean)   
    Merge the properties defined in "nodejs.config" with the one present on
    the existing "~/.npmrc" file, default to true
*   `nodejs.config.http_proxy` (string)
    The HTTP proxy connection url, default to the one defined by the 
    "masson/core/proxy" module.
*   `nodejs.config.https-proxy` (string)
    The HTTPS proxy connection url, default to the one defined by the 
    "masson/core/proxy" module.
*   `nodejs.version` (string)
*   `nodejs.version` (string)

Example:

```json
{
  "nodejs": {
    "version": "stable",
    "config": {
      "registry": "http://some.aternative.registry"
    }
  }
}
```

    module.exports = ({deps, options}) ->

## Environment

      options.version ?= 'stable'
      options.merge ?= true
      options.method ?= 'binary' # one of "binary" or "n"
      throw Error 'Method not handled' unless options.method in ['binary', 'n']

## Configuration

      options.config ?= {}
      options.config['registry'] ?= 'http://registry.npmjs.org/'
      if deps.proxy
        options.config['proxy'] ?= deps.proxy.options.http_proxy
        options.config['https-proxy'] ?= deps.proxy.options.http_proxy

## User Configuration

Npm properties can be defined by the system module through the "npmrc" user 
configuration.

      options.users ?= {}
      for username, user of options.users
        throw Error "User Not Defined: module system must define the user #{username}" unless deps.system.options.users[username]
        user = merge {}, deps.system.options.users[username], user
        config.target ?= "#{user.home}/.npmrc"
        config.uid ?= user.uid or user.name
        config.gid ?= user.gid or user.group
        config.config ?= merge {}, options.config, use.npmrc, user.config
        config.merge ?= options.merge
