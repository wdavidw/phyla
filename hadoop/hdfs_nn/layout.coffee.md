# HDFS Datanode Layout

    module.exports = header: 'HDFS NN layout', handler: (options) ->

## Register

      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'

## Wait

Wait for the DataNodes and NameNodes to be started.

      @call 'ryba/hadoop/hdfs_dn/wait', once: true, options.wait_hdfs_dn
      @call 'ryba/hadoop/hdfs_nn/wait', once: true, conf_dir: options.conf_dir, options.wait

## HDFS layout

Set up the directories and permissions inside the HDFS filesytem. The layout is inspired by the
[Hadoop recommandation](http://hadoop.apache.org/docs/r2.1.0-beta/hadoop-project-dist/hadoop-common/ClusterSetup.html)
on the official Apache website. The following folder are created:

```
drwxr-xr-x   - hdfs   hadoop      /
drwxr-xr-x   - hdfs   hadoop      /apps
drwxrwxrwt   - hdfs   hadoop      /tmp
drwxr-xr-x   - hdfs   hadoop      /user
drwxr-xr-x   - hdfs   hadoop      /user/hdfs
```

      @call header: 'HDFS layout', (opts)->
        @wait.execute
          cmd: mkcmd.hdfs options.hdfs_krb5_user, "hdfs --config '#{options.conf_dir}' dfs -test -d /"
        @system.execute
          cmd: mkcmd.hdfs options.hdfs_krb5_user, """
          hdfs --config '#{options.conf_dir}' dfs -chmod 755 /
          """
        @system.execute
          cmd: mkcmd.hdfs options.hdfs_krb5_user, """
          if hdfs --config '#{options.conf_dir}' dfs -test -d /tmp; then exit 2; fi
          hdfs --config '#{options.conf_dir}' dfs -mkdir /tmp
          hdfs --config '#{options.conf_dir}' dfs -chown #{options.user.name}:#{options.hadoop_group.name} /tmp
          hdfs --config '#{options.conf_dir}' dfs -chmod 1777 /tmp
          """
          code_skipped: 2
        , (err, executed, stdout) ->
          options.log? 'Directory "/tmp" prepared' if executed
        @system.execute
          cmd: mkcmd.hdfs options.hdfs_krb5_user, """
          if hdfs --config '#{options.conf_dir}' dfs -test -d /user; then exit 2; fi
          hdfs --config '#{options.conf_dir}' dfs -mkdir /user
          hdfs --config '#{options.conf_dir}' dfs -chown #{options.user.name}:#{options.hadoop_group.name} /user
          hdfs --config '#{options.conf_dir}' dfs -chmod 755 /user
          hdfs --config '#{options.conf_dir}' dfs -mkdir /user/#{options.user.name}
          hdfs --config '#{options.conf_dir}' dfs -chown #{options.user.name}:#{options.hadoop_group.name} /user/#{options.user.name}
          hdfs --config '#{options.conf_dir}' dfs -chmod 755 /user/#{options.user.name}
          """
          code_skipped: 2
        , (err, executed, stdout) ->
          options.log? 'Directory "/user/{test_user}" prepared' if executed
        @system.execute
          cmd: mkcmd.hdfs options.hdfs_krb5_user, """
          if hdfs --config '#{options.conf_dir}' dfs -test -d /apps; then exit 2; fi
          hdfs --config '#{options.conf_dir}' dfs -mkdir /apps
          hdfs --config '#{options.conf_dir}' dfs -chown #{options.user.name}:#{options.hadoop_group.name} /apps
          hdfs --config '#{options.conf_dir}' dfs -chmod 755 /apps
          """
          code_skipped: 2
        , (err, executed, stdout) ->
          options.log? 'Directory "/apps" prepared' if executed

## HDP Layout

      @system.execute
        header: 'HDP Layout'
        cmd: mkcmd.hdfs options.hdfs_krb5_user, """
        version=`readlink /usr/hdp/current/hadoop-client | sed 's/.*\\/\\(.*\\)\\/hadoop/\\1/'`
        hdfs --config '#{options.conf_dir}' dfs -mkdir -p /hdp/apps/$version
        hdfs --config '#{options.conf_dir}' dfs -chown -R  #{options.user.name}:#{options.hadoop_group.name} /hdp
        hdfs --config '#{options.conf_dir}' dfs -chmod 555 /hdp
        hdfs --config '#{options.conf_dir}' dfs -chmod 555 /hdp/apps
        hdfs --config '#{options.conf_dir}' dfs -chmod -R 555 /hdp/apps/$version
        """
        trap: true
        unless_exec: mkcmd.hdfs options.hdfs_krb5_user, """
        version=`readlink /usr/hdp/current/hadoop-client | sed 's/.*\\/\\(.*\\)\\/hadoop/\\1/'`
        hdfs --config '#{options.conf_dir}' dfs -test -d /hdp/apps/$version
        """

## Test User

Create a Unix and Kerberos test user, by default "test" and execute simple HDFS commands to ensure
the NameNode is properly working. Note, those commands are NameNode specific, meaning they only
afect HDFS metadata.

      @hdfs_mkdir
        header: 'User Test'
        target: "/user/#{options.test.user.name}"
        user: options.test.user.name
        group: options.test.group.name
        mode: 0o0750
        conf_dir: options.conf_dir
        krb5_user:
          principal: options.hdfs_site['dfs.namenode.kerberos.principal'].replace '_HOST', options.fqdn
          keytab: options.hdfs_site['dfs.namenode.keytab.file']

## Dependencies

    mkcmd = require '../../lib/mkcmd'
