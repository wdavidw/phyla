
# HDFS Chown

Set ownership on an HDFS File/Directory using [webhdfs api](https://hadoop.apache.org/docs/r1.0.4/webhdfs.html).

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
  
## Source Code

    module.exports = ({options}, callback) ->
      return callback Error 'Missing krb5 user' unless options.krb5_user
      return callback Error 'Missing owner' unless options.owner
      return callback Error 'Missing group' unless options.group
      return callback Error 'Missing target' unless options.target
      active_url = null
      @registry.register ['hdfs','active'], require './active'
      options.header = null
      do_owner = true
      do_permission = true
      @registry.register ['hdfs','active'], require './active'
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
                    @log message: "Target #{options.target} does not exist", level: 'INFO'
                  else
                    throw Error data.RemoteException
              else
                ## check owner and permission
                @log message: "Target #{options.target} exist", level: 'INFO'
                @log message: "Checking permission and owner", level: 'INFO'
                @log message: "current owner: #{data['FileStatus']['owner']} target owner: #{options.owner}", level: 'INFO'                
                @log message: "current group: #{data['FileStatus']['group']} target group: #{options.group}", level: 'INFO'                
                @log message: "current permission: #{data['FileStatus']['permission']} target permission: #{options.mode}", level: 'INFO'                
                do_owner = (data['FileStatus']['group'] isnt options.group) || (data['FileStatus']['owner'] isnt options.owner)
                do_permission = (data['FileStatus']['permission'] isnt options.mode)
                @log message: "skipping SETOWNER", level: 'INFO' unless do_owner
                @log message: "skipping SETPERMISSION", level: 'INFO' unless do_permission
            catch err
              throw err
      @call
        if: -> do_owner
      , ->
        @system.execute
          local: options.local
          cmd: mkcmd.hdfs options.krb5_user, "/bin/bash -c 'curl --fail  --negotiate -X PUT -k -u : \"#{active_url}/webhdfs/v1#{options.target}?op=SETOWNER&owner=#{options.owner}&group=#{options.group}\"'"
      @call
        if: -> do_permission
      , ->
        @system.execute
          local: options.local
          cmd: mkcmd.hdfs options.krb5_user, "/bin/bash -c 'curl --fail  --negotiate -X PUT -k -u : \"#{active_url}/webhdfs/v1#{options.target}?op=SETPERMISSION&permission=#{options.mode}\"'"
      @next callback

## Dependencies

    mkcmd = require '../../mkcmd'