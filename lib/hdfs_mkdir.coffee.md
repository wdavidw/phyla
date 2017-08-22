
# `hdfs_mkdir(options, callback)`

Create an HDFS directory.

Options include:

*   `target`   
*   `krb5_user`   
*   `krb5_user.principal`   
*   `krb5_user.password`   
*   `krb5_user.keytab`   
*   `mode`   
*   `user`   
*   `group`   
*   `parent`   
*   `parent.mode`   
*   `parent.user`   
*   `parent.group`   

## Source Code

    module.exports = (options, callback) ->
      throw callback Error "Required option: 'target'" unless options.target
      options.mode ?= ''
      options.mode = mode.stringify options.mode
      options.user ?= ''
      options.group ?= ''
      options.parent ?= {}
      options.parent.mode ?= options.mode
      options.parent.mode = mode.stringify options.parent.mode if options.parent.mode
      options.parent.user ?= options.user
      options.parent.group ?= options.group
      wrap = (cmd) ->
        return cmd unless options.krb5_user
        if options.krb5_user.password
          "echo '#{options.krb5_user.password}' | kinit #{options.krb5_user.principal} >/dev/null && {\n#{cmd}\n}"
        else if options.krb5_user.keytab
          "kinit -kt #{options.krb5_user.keytab} #{options.krb5_user.principal} >/dev/null && {\n#{cmd}\n}"
      conf_opt = if options.conf_dir then "--config #{options.conf_dir}" else '--config /etc/hadoop/conf'
      @system.execute
        cmd: wrap """
        target="#{options.target}"
        if hdfs #{conf_opt} dfs -test -d $target; then
          # TODO: compare permissions and ownership
          exit 3;
        fi
        function create_dir {
          dir=$1
          mode=$2
          user=$3
          group=$4
          echo "Create dir $dir"
          # Use -p to prevent race conditions
          hdfs #{conf_opt} dfs -mkdir -p $dir
          if [ -n "$mode" ]; then
            echo "Change permissions to $mode"
            hdfs #{conf_opt} dfs -chmod $mode $dir
          fi
          if [ -n "$user" ]; then
            echo "Change owner ownership to $user"
            hdfs #{conf_opt} dfs -chown $user $dir
          fi
          if [ -n "$group" ]; then
            echo "Change group ownership to $group"
            hdfs #{conf_opt} dfs -chgrp $group $dir
          fi
        }
        function create_parent_dir {
          local dir=`dirname $1`
          if [ $dir == "/" ]; then return; fi
          if hdfs #{conf_opt} dfs -test -d $dir; then return; fi
          create_parent_dir $dir
          # echo "Create parent directory: $dir"
          create_dir \
            "$dir" \
            "#{options.parent.mode or ''}" \
            "#{options.parent.user or ''}" \
            "#{options.parent.group or ''}"
        }
        create_parent_dir $target
        create_dir \
          $target \
          "#{options.mode or ''}" \
          "#{options.user or ''}" \
          "#{options.group or ''}"
        """
        code_skipped: 3
        trap: true
      .then callback

## Dependecies

    {mode} = require 'nikita/lib/misc'
