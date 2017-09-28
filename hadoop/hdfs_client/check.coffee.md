
# Hadoop HDFS Client Check

Check the access to the HDFS cluster.

    module.exports = header: 'HDFS Client Check', handler: (options) ->

Wait for the DataNode and NameNode.

      @call 'ryba/hadoop/hdfs_dn/wait', once: true, options.wait_hdfs_dn
      @call 'ryba/hadoop/hdfs_nn/wait', once: true, options.wait_hdfs_nn, conf_dir: options.conf_dir

## NameNode

Run an HDFS command requiring a NameNode. The NameNode will create the home
directory for the test user, we simply wait for the creation to be made once
the NameNode has started.

      @system.execute.assert
        header: 'NameNode'
        label_true: 'CHECKED',
        cmd: mkcmd.test @, "hdfs dfs -test -d /user/#{options.test.user.name}"
        retry: 5
        sleep: 5000

## DataNode

Run an HDFS command requiring a DataNode.

      @system.execute
        header: 'DataNode'
        cmd: mkcmd.test @, """
        if hdfs dfs -test -f /user/#{options.test.user.name}/#{options.hostname}-hdfs; then exit 2; fi
        hdfs dfs -touchz /user/#{options.test.user.name}/#{options.hostname}-hdfs
        """
        code_skipped: 2

## Check Kerberos Mapping

Kerberos Mapping is configured in "core-site.xml" by the
"hadoop.security.auth_to_local" property. Hadoop provided a comman which take
the principal name as argument and print the converted user name.

      @system.execute
        header: 'Kerberos Mapping'
        cmd: "hadoop org.apache.hadoop.security.HadoopKerberosName #{options.test.krb5.user.principal}"
        if: options.core_site['hadoop.security.authentication'] is 'kerberos'
      , (err, _, stdout) ->
        throw Error "Invalid mapping" if not err and stdout.indexOf("#{options.test.krb5.user.principal} to #{options.test.user.name}") is -1

## Dependencies

    mkcmd = require '../../lib/mkcmd'
