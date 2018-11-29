
# HDFS Mkdir

Create a directory on an HDFS File/Directory using [webhdfs api](https://hadoop.apache.org/docs/r1.0.4/webhdfs.html).
If owner and group are passed in options, it will also set ownerships.

## Options

* `nn_url` (String, array)    
  The url like https://master01.metal.ryba:50470. RYBA will take every url an will
  request Namenode's metrics to get the active status.
* `krb5_user` (obj)   
  A principal which has suffisiant permission to request namenode api.
* `target` (string)   
  The target File/directory to set owner on. Required.   
* `owner` (string)   
  The username as a string. Required.   
* `group` (string)
  the groupname. Required.   
* `mode` (string)
  the mode to apply on target. Required.   

## Source Code

    module.exports = ({options}, callback) ->
      return callback Error 'missing namenode url' unless options.nn_url
      return callback Error 'Missing krb5 user' unless options.krb5_user
      return callback Error 'Missing target directory' unless options.target
      active_url = null
      file_exists = null
      do_owner = options.owner? and options.group?
      count = 0
      if options.target.indexOf('hdfs://') is 0 
        for i in [0..options.target.length]
          count++ if options.target[i] is '/'
          if count == 3
            options.target = options.target.slice(i)
            break
      options.mode ?= '750'
      options.debug ?= false
      options.header = null
      @log message: "Entering hdfs mkdir", level: 'DEBUG', module: 'ryba/lib/actions/hdfs/active'
      @registry.register ['hdfs','active'], require './active'
      @registry.register ['hdfs','chown'], require './chown'
      @call ->
        @hdfs.active options
        , (err, obj) ->
          active_url = obj.active 
      @call
        shy: true
      , ->
        @system.execute
          cmd: mkcmd.hdfs options.krb5_user, "/bin/bash -c 'curl -H \"Content-Type: application/json\"  --negotiate -X GET -k -u : \"#{active_url}/webhdfs/v1#{options.target}?op=GETFILESTATUS\"'"
        , (err, obj) ->
            throw err if err
            try
              data = JSON.parse obj.stdout
              if data.RemoteException?.exception?
                switch data.RemoteException.exception
                  when 'FileNotFoundException'
                    file_exists = false
                    @log message: "Directory #{options.target} does not exist", level: 'INFO'
                  else
                    throw Error data.RemoteException
              else
                ## check owner and permission
                @log message: "#{options.target} already exist", level: 'INFO'
                file_exists = true
                throw Error 'Target is not a directory' unless  data['FileStatus']['type'] is 'DIRECTORY'
            catch err
              throw err
      @call
        unless: -> file_exists 
      ,  (_ , cb)->
        @system.execute
          cmd: mkcmd.hdfs options.krb5_user, "/bin/bash -c 'curl --negotiate -X PUT -k -u : \"#{active_url}/webhdfs/v1#{options.target}?op=MKDIRS&permission=#{options.mode}\"'"
        @next cb
      @hdfs.chown options
      @next callback
      
## Dependencies

    mkcmd = require '../../mkcmd'