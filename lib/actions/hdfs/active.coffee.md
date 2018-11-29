
# HDFS Actions to get active namenode

## Options

* `nn_url` (String, array)    
  The url like https://master01.metal.ryba:50470. RYBA will take every url an will
  request Namenode's metrics to get the active status.
* `krb5_user` (obj)   
  A principal which has suffisiant permission to request namenode api.

## Source Code

    module.exports = ({options}, callback) ->
      return callback Error 'missing namenode url' unless options.nn_url
      return callback Error 'Missing krb5 user' unless options.krb5_user
      options.nn_url = [options.nn_url] unless Array.isArray options.nn_url
      options.debug ?= false
      detected = false
      options.header = null
      {krb5_user} = options
      @log message: "Entering hdfs active", level: 'DEBUG', module: 'ryba/lib/actions/hdfs/active'
      @each options.nn_url, ({options}, cb) ->
        nn_url = options.key
        @log message: "Testing Namenode #{nn_url}", level: 'DEBUG', module: 'ryba/lib/actions/hdfs/active'
        @system.execute
          shy: true
          cmd: mkcmd.hdfs krb5_user, "/bin/bash -c 'curl --negotiate -X GET -k -u : \"#{nn_url}/jmx?qry=Hadoop:service=NameNode,name=NameNodeStatus\"'"
        , (err, obj) ->
            return callback err if err
            try
              data = JSON.parse obj.stdout
              if data.beans[0]['State'] is 'active'
                detected = true
                @log message: "Active Namenode #{nn_url} detected", level: 'DEBUG', module: 'ryba/lib/actions/hdfs/active'
                return callback err, status: false, active: nn_url
            catch err
              callback err
        @next cb
      @next (err) ->
        return callback err if err
        return callback "Failed to detect active NN" unless detected

## Dependencies

    mkcmd = require '../../mkcmd'