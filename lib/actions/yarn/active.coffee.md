
# YARN Action to get active RM

* `yarn_url` (String, array)    
  The url like https://master01.metal.ryba:50470. RYBA will take every url and will
  request YARN ResourceManager's metrics to get the active status.
* `krb5_user` (obj)   
  A principal which has suffisiant permission to request RM api.

    module.exports = ({options}, callback) ->
      return callback Error 'missing ResourceManager url' unless options.yarn_url
      return callback Error 'Missing krb5 user' unless options.yarn_user
      options.yarn_url = [options.yarn_url] unless Array.isArray options.yarn_url
      options.debug ?= false
      detected = false
      {yarn_user} = options
      @log message: "Entering yarn active", level: 'DEBUG', module: 'ryba/lib/actions/yarn/active'
      @each options.yarn_url, ({options}, cb) ->
        yarn_url = options.key
        @log message: "Testing ResourceManager #{yarn_url}", level: 'DEBUG', module: 'ryba/lib/actions/yarn/active'
        @system.execute
          shy: true
          cmd: mkcmd.hdfs yarn_user, "/bin/bash -c 'curl --negotiate -X GET -k -u : \"#{yarn_url}/app/v1/services\"'"
        , (err, {status, stdout}) ->
            return callback err if err
            if stdout.indexOf('standby') is -1
              detected = true
              return callback err, status: false, active: yarn_url
        @next cb
      @next (err) ->
        return callback err if err
        return callback "Failed to detect active ResourceManager" unless detected

## Dependencies

    mkcmd = require '../../mkcmd'