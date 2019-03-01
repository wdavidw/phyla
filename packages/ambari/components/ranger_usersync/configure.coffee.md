
# Ambari Ranger UserSync Configure

    module.exports = ({deps, options}) ->

## Identities

By default, merge group and user from the Ranger admin configuration.

      options.group = mixme deps.ranger_admin[0].options.group, options.group
      options.user = mixme deps.ranger_admin[0].options.user, options.user
    
      options.config ?= {}
      
## SSL

      options.ssl = mixme deps.ssl.options, options.ssl
      options.ssl.enabled ?= !!deps.ssl
      if options.ssl.enabled
        throw Error "Required Option: ssl.cert" if  not options.ssl.cert
        throw Error "Required Option: ssl.key" if not options.ssl.key
        throw Error "Required Option: ssl.cacert" if not options.ssl.cacert
        # options.config['options.ssl'] ?= 'true'
        options.config['ranger.usersync.keystore.file'] ?= "/etc/security/serverKeys/ranger-usersync-keystore.jks"
        throw Error "Required Option: config['ranger.usersync.keystore.password']" unless options.config['ranger.usersync.keystore.password']
        options.config['ranger.usersync.truststore.file'] ?= "/etc/security/clientKeys/ranger-usersync-truststore.jks"
        throw Error "Required Option: config['ranger.usersync.truststore.password']" unless options.config['ranger.usersync.truststore.password']

## Dependencies

    mixme = require 'mixme'
