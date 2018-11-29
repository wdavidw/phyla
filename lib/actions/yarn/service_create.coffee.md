
# YARN Service API Create

Create a YARN 3 service to be deployed as long running service example.
It uses [YARN Service API](http://hadoop.apache.org/docs/r3.1.0/hadoop-yarn/hadoop-yarn-site/yarn-service/YarnServiceAPI.html)

## Options

* `yarn_url` (String, array)    
  RYBA will try  every url to post service creation.
* `yarn_user` (obj)   
  A principal which has suffisiant permission to request YARN Service API.
* `name` (String)...    
  The yarn service name. Required   
* `version` (obj)   
The version of the service you want to run. Required  
* `lifetime` (obj)   
  Life time (in seconds) of the service from the time it reaches the STARTED state 
  (after which it is automatically destroyed by YARN). set to null for unlimited.
* `components` (obj)
  The object describe the layout of the service. Number of contnainer per component.
  Site configuration. RYBA will not check the consistences of components as it is
  let to administrator will.
* `krb5_principal` (String).
  The principal which will launch the service on yarn.   
* `krb5_keytab` (String).
  The keytabcorresponding to principal. This should be an uri. The recommendation is
  to make it point to hdfs so every node shares a keytab, otherelse administrator will have
  to manually put the keytab on every node.   

## Source Code

    module.exports = ({options}, callback) ->
      return callback Error 'Missing yarn url' unless options.yarn_url?
      return callback Error 'Missing yarn_user' unless options.yarn_user?
      return callback Error 'Missing Service name' unless options.name?
      return callback Error 'Missing group of target file' if options.target? and not options.group?
      return callback Error 'Missing user of target file' if options.target? and not options.user?
      if not options.source?
        return callback Error 'Missing Service version' if options.version?
        return callback Error 'Missing Service components' unless options.components?
        return callback Error 'Missing krb5_user' unless options.krb5_user?
        for component in options.components
          for file in component.configuration.files
            if file.type is 'XML'
              for prop, value of file.properties
                if Array.isArray value
                  file.properties[prop] = value.join(',')
      options.mode ?= 0o640
      options.lifetime ?= null
      state = null
      options.description ?= "Service #{options.name} with version #{options.version}"
      if not options.source?
        options.service ?=
          name: options.name
          version: options.version
          lifetime: options.lifetime
          description: options.description
          components: options.components
          kerberos_principal:
            principal_name: options.krb5_user.principal
            keytab: options.krb5_user.keytab
      else
        options.target = options.source
      active_url = null
      @registry.register ['yarn','active'], require './active'
      @registry.register ['yarn','service', 'get'], require './service_get'
      @registry.register ['yarn','service', 'start'], require './service_start'
      @call (_, cb)->
        @yarn.active options
        , (err, obj) ->
          active_url = obj.active
        @next cb
      @call (_, cb) ->
        @file
          unless: options.source?
          mode: options.mode
          user: options.user
          group: options.group
          target: options.target
          content: JSON.stringify options.service, null, 2
        @call
        @call (_, cb) ->
          @yarn.service.get
            name: options.name
            yarn_url: options.yarn_url
            yarn_user: options.yarn_user
          , (err, response) ->
            return cb err if err
            if response?.state
              state = response.state
              return cb null, state in ['STARTED','FAILED', 'STOPPED']
            else
              return cb null, false
        @system.execute
          unless: -> @status -1
          if: options.target
          cmd: mkcmd.hdfs options.yarn_user, """
            curl --fail -H "Content-Type: application/json" --negotiate -X POST -k -u : \
            -d @#{options.target} \
            "#{active_url}/app/v1/services"
          """
        @system.execute
          unless: -> @status -2
          debug: true
          unless: options.target
          cmd: mkcmd.hdfs options.yarn_user, """
            curl --fail -H "Content-Type: application/json" --negotiate -X POST -k -u : \
            -d '#{JSON.stringify }' \
            "#{active_url}/app/v1/services"
          """
        @yarn.service.start
          if: -> state in ['FAILED', 'STOPPED']
          name: options.name
          yarn_url: options.yarn_url
          yarn_user: options.yarn_user
        @next cb
      @next callback

## Dependencies

    mkcmd = require '../../mkcmd'