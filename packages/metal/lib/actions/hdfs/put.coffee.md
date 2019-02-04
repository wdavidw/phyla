
# HDFS Put

Put a File in HDFS using [webhdfs api](https://hadoop.apache.org/docs/r1.0.4/webhdfs.html).

## Options

* `nn_url` (String, array)    
  The url like https://master01.metal.ryba:50470. RYBA will take every url an will
  request Namenode's metrics to get the active status.
* `krb5_user` (obj)   
  A principal which has suffisiant permission to request namenode api.
* `source` (string)   
  The source file needed to be uploaded. Required.   
* `local` (boolean)   
  is the source file on local compute or remote server. false by default.   
* `target` (string)
  the target file name in hdfs. Required.   

## Source Code

    module.exports = ({options}, callback) ->
      return callback Error 'Missing krb5 user' unless options.krb5_user
      return callback Error 'missing source' unless options.source
      return callback Error 'Missing target' unless options.target
      options.local ?= false
      active_url = null
      file_exists = false
      should_upload = true
      file_checksum = null
      local_checksum = null
      options.mode ?= '644'
      count = 0
      if options.target.indexOf('hdfs://') is 0 
        for i in [0..options.target.length]
          count++ if options.target[i] is '/'
          if count == 3
            options.target = options.target.slice(i)
            break
      options.tmpfile = "/tmp/#{path.basename options.target}"
      @registry.register ['hdfs','active'], require './active'
      @registry.register ['hdfs','chown'], require './chown'
      @call ->
        @hdfs.active options
        , (err, obj) ->
          active_url = obj.active
      @call
        shy: true
      ,  (_ , cb)->
        @system.execute
          cmd: mkcmd.hdfs options.krb5_user, "/bin/bash -c 'curl --negotiate -X GET -k -u : \"#{active_url}/webhdfs/v1#{options.target}?op=GETFILESTATUS\"'"
        , (err, data) ->
            return cb err if err
            error = null
            try
              response = JSON.parse data.stdout
              if response['RemoteException']?
                if response['RemoteException']['exception'] is 'FileNotFoundException'
                  @log message: "File #{options.target} does not exist", level: 'INFO'
                  file_exists = false
                else
                  throw Error response['RemoteException']
              else
                if response['FileStatus']?
                  throw Error "#{options.target} is not a file " unless  response['FileStatus']['type'] is 'FILE'
                  @log message: "File #{options.target} does already exist", level: 'INFO'
                  file_exists = true
            catch err
              error = err
            finally
              cb error, false
      @call
        if: -> file_exists
      , ->
        @system.execute
          shy: true
          cmd: mkcmd.hdfs options.krb5_user, "/bin/bash -c 'curl -L --negotiate -X GET -k -u : \"#{active_url}/webhdfs/v1#{options.target}?op=OPEN\" > #{options.tmpfile}'"
        @system.execute
          shy: true
          cmd: """
            openssl md5 #{options.tmpfile}
          """
        , (err, data) ->
            throw err if err
            try
              file_checksum = data?.stdout?.split('=')[1]?.trim()
              @log message: "File hdfs checksum #{options.target} #{file_checksum}", level: 'INFO'
              # if file_checksum?
              file_exists = true
            catch err
              throw err
      @call
        if: -> file_exists
      , ->
        @system.execute
          shy: true
          cmd: """
            openssl md5 #{options.source} | tail -n1
          """
        , (err, data) ->
            throw err if err
            try
              local_checksum = data?.stdout?.split('=')[1]?.trim()
              @log message: "File local checksum #{options.source} #{local_checksum}", level: 'INFO'
              # if local_checksum
              should_upload = !(file_checksum is local_checksum)
            catch err
              throw err            
      @call ->
        @system.execute
          if: -> (not file_exists) or should_upload
          local: options.local
          cmd: mkcmd.hdfs options.krb5_user, "/bin/bash -c 'curl -H \"Content-Type: application/octet-stream\" --negotiate -X PUT -L -k -T  #{options.source} -u : \"#{active_url}/webhdfs/v1#{options.target}?op=CREATE#{if should_upload then '&overwrite=true' else ''}\"'"
      if options.owner or options.group
        @hdfs.chown options
        @next callback
      else
        @next callback

## Dependencies

    mkcmd = require '../../mkcmd'
    path = require 'path'