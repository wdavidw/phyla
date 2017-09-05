
# HBase Master Layout

    module.exports = header: 'HBase Master Layout', handler: (options) ->
    
## Register

      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'

## Wait

Wait for HDFS to be started.

      @call 'ryba/hadoop/hdfs_nn/wait', once: true, options.wait_hdfs_nn, conf_dir: options.hdfs_conf_dir

## HDFS Layout

      @wait.execute
        cmd: mkcmd.hdfs @, "hdfs --config #{options.hdfs_conf_dir} dfs -test -d /apps"

## HDFS

Create the directory structure with correct ownerships and permissions.


      @hdfs_mkdir
        header: 'Data'
        target: options.hbase_site['hbase.rootdir']
        user: options.user.name
        group: options.group.name
        mode: 0o0711
        parent:
          mode: 0o0711
        conf_dir: options.hdfs_conf_dir
        krb5_user: options.hdfs_admin
      @hdfs_mkdir
        header: 'Staging'
        target: options.hbase_site['hbase.bulkload.staging.dir']
        user: options.user.name
        group: options.group.name
        mode: 0o0711
        parent:
          mode: 0o0711
        conf_dir: options.hdfs_conf_dir
        krb5_user: options.hdfs_admin
        
      # migration: wdavidw 070829, remove if @hdfs_mkdir above worked as expected
      # @call ->
      #   dirs = options.hbase_site['hbase.bulkload.staging.dir'].split '/'
      #   throw err 'Invalid Property: "hbase.bulkload.staging.dir"' unless dirs.length > 2 and path.posix.join('/', dirs[0], '/', dirs[1]) is '/apps'
      #   for dir, index in dirs.slice 2
      #     dir = dirs.slice(0, 3 + index).join '/'
      #     cmd = """
      #     if hdfs --config #{options.hdfs_conf_dir} dfs -ls #{dir} &>/dev/null; then exit 2; fi
      #     hdfs --config #{options.hdfs_conf_dir} dfs -mkdir #{dir}
      #     hdfs --config #{options.hdfs_conf_dir} dfs -chown #{options.user.name} #{dir}
      #     """
      #     cmd += "\nhdfs --config #{options.hdfs_conf_dir} dfs -chmod 711 #{dir}"  if 3 + index is dirs.length
      #     @system.execute
      #       cmd: mkcmd.hdfs @, cmd
      #       code_skipped: 2

# Module dependencies

    path = require 'path'
    mkcmd = require '../../lib/mkcmd'
