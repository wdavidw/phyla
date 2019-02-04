
# HDFS Upload Action

Signature is `hdfs_upload(options)`.

## Options

* `cwd` (string)string | boolean
  Current working directory relative to source file.
* `krb5_user.password` (string)   
  Kerberos princpal password.
* `krb5_user.principal` (string)   
  Kerberos Principal
* `lock` (string)string | boolean
  Temporary lock file.
* `mode` (string)   
  Permission of the file
* `owner` (string)   
  Username owning the file.
* `source` (string)   
  Local file to upload, can be a globing expression referencing a single file.
* `target` (string)   
  HDFS file of the target.
* `clean` (string|boolean)   
  Removing files before uploading. Expect a lobbing expression or boolean true
  corresponding to the "source" option.

## Exemple

```coffee
@registry.register 'hdfs_upload', '@rybajs/metal/lib/hdfs_upload'
@hdfs_upload
  source: "/usr/hdp/current/hive-metastore/lib/hive-exec-#{version}.jar"
  target: "/apps/hive/install/hive-exec-#{version}.jar"
  clean: "/apps/hive/install/hive-exec-*.jar"
  lock: "/tmp/hive-exec-#{version}.jar"
```

## Source Code

    module.exports = ({options}) ->
      throw Error "Required option 'source'" unless options.source
      throw Error "Required option 'target'" unless options.target
      options.lock ?= "/tmp/ryba-#{string.hash options.target}"
      options.clean ?= ''
      options.clean = options.source if options.clean is true
      options.mode ?= '444'
      options.parent_mode ?= '755'
      options.owner ?= ''
      options.parent_owner ?= options.owner
      @system.execute
        cmd: mkcmd.hdfs options.krb5_user, """
        source=#{options.source}
        if [ ! -f "$source" ] ; then exit 1; fi
        mode=#{options.mode}
        owner=#{options.owner}
        parent_mode=#{options.parent_mode}
        parent_owner=#{options.parent_owner}
        link=`echo $source | sed  's|\\(.*/hdp/current/[^/]*\\)/.*|\\1|'`
        version=`readlink $link | sed  's|.*/hdp/\\([^/]*\\)/.*|\\1|'`
        target=#{options.target}
        lock_file=#{options.lock}
        timeout=240 # 4 minutes
        # Not used but shown as a possible alternative:
        # function get_leader {
        #   hdfs dfs -mkdir -p $lock_file
        #   hdfs dfs -touchz $lock_file/#{options.id}
        #   oldest_time=''
        #   oldest_file=''
        #   for file in `hdfs dfs -ls -C $lock_file`; do
        #     crdate=$((`hdfs dfs -stat "%Y" $file`/1000))
        #     if [ -z $oldest_time ] || [ $oldest_time -lt $crdate ]; then
        #       oldest_time=$crdate
        #       oldest_file=$file
        #     fi
        #   done
        #   echo $oldest_file
        # }
        # leader=`get_leader`
        # echo '**** leader ' $leader
        function lock {
          if hdfs dfs -mkdir $lock_file; then
            echo "Lock created"
          else
            echo 'lock exist, check if valid'
            now=`date '+%s'`
            crdate=$((`hdfs dfs -stat "%Y" $lock_file`/1000))
            if [ $(($now - $crdate)) -le $timeout ]; then
              sleep_time=$(($timeout - $crdate + $now + 5))
              echo crdate $crdate
              echo now $now
              echo sleep_time $sleep_time
              echo "Lock is active, wait for ${sleep_time}s until expiration"
              sleep $sleep_time
              if hdfs dfs -test -d $lock_file; then
                echo "Lock still present after waiting"
                exit 1
              fi
              if hdfs dfs -test -f $target; then
                echo "File uploaded in parallel by somebody else"
                exit 3
              fi
              echo "Lock released, attemp to upload file"
            else
              echo "Lock has expired $(($now - $crdate + $timeout))s ago, pursue uploading"
              hdfs dfs -rm -r -skipTrash $lock_file
              lock
            fi
          fi
        }
        lock
        echo "Upload file to $(dirname $target)"
        function create_parent_dir {
          local dir=`dirname $1`
          if [ $dir == "/" ]; then return; fi
          if hdfs dfs -test -d $dir; then return; fi
          create_parent_dir $dir
          echo "Create parent directory: $dir"
          hdfs dfs -mkdir -p $dir
          hdfs dfs -chmod -R $parent_mode $dir
          if [ -n "${parent_owner}" ]; then
            hdfs dfs -chown ${parent_owner} $dir
          fi
        }
        create_parent_dir $target
        if [ -n "#{options.clean}" ]; then
          for file in `hdfs dfs -find '#{options.clean}'`; do echo hdfs dfs -rm $file; done
        fi
        echo "Copy $source to directory $(dirname $target)"
        hdfs dfs -copyFromLocal $source $(dirname $target)
        echo "Update target permissions"
        hdfs dfs -chmod -R $mode $target
        if [ -n "${owner}" ]; then
          hdfs dfs -chown ${owner} $target
        fi
        hdfs dfs -test -f $target
        echo "Release lock"
        hdfs dfs -rm -r $lock_file
        """
        trap: true
        bash: true
        code_skipped: 3
        unless_exec: mkcmd.hdfs options.krb5_user, """
        source=#{options.source}
        link=`echo $source | sed  's|\\(.*/hdp/current/[^/]*\\)/.*|\\1|'`
        version=`readlink $link | sed  's|.*/hdp/\\([^/]*\\)/.*|\\1|'`
        target=#{options.target}
        hdfs dfs -test -f $target
        """
        cwd: options.cwd

## Dependencies

    mkcmd = require './mkcmd'
    string = require '@nikitajs/core/lib/misc/string'
