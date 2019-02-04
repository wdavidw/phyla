
# YARN Service API START

Start a YARN 3 service using [YARN Service API](http://hadoop.apache.org/docs/r3.1.0/hadoop-yarn/hadoop-yarn-site/yarn-service/YarnServiceAPI.html)

## Options

* `yarn_url` (String, array)    
  RYBA will try  every url to post service creation.
* `yarn_user` (obj)   
  A principal which has suffisiant permission to request the YARN Service API and
  whose ACL allows the service start.
* `name` (String)...    
  The yarn service name. Required   

## Source Code

    module.exports = ({options}, callback) ->
      return callback Error 'Missing yarn url' unless options.yarn_url?
      return callback Error 'Missing yarn_user' unless options.yarn_user?
      return callback Error 'Missing Service name' unless options.name?
      active_url = null
      response = null
      @registry.register ['yarn','active'], require './active'
      @call (_, cb)->
        @yarn.active options
        , (err, obj) ->
          active_url = obj.active
        @next cb
      @call (_, cb) ->
        @system.execute
          cmd: mkcmd.hdfs options.yarn_user, """
            curl --fail -H "Content-Type: application/json" --negotiate -X PUT -k -u : \
            "#{active_url}/app/v1/services/#{options.name}" -d '#{JSON.stringify state: 'STARTED'}'
          """
        @next cb
      @next callback
        

## Dependencies

    mkcmd = require '../../mkcmd'