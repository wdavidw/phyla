
# Hadoop ZKFC Start

Start the NameNode service as well as its ZKFC daemon.

In HA mode, to ensure that the leadership is assigned to the desired active
NameNode, the ZKFC daemons on the standy NameNodes wait for the one on the
active NameNode to start first.

    module.exports = header: 'HDFS ZKFC Start', handler: (options) ->

## Wait

Wait for Kerberos, ZooKeeper and HDFS to be started.

      # @call once: true, 'masson/core/krb5_client/wait'
      # @call once: true, 'ryba/zookeeper/server/wait'
      # @call once: true, 'ryba/hadoop/hdfs_jn/wait'
      @call once: true, 'ryba/hadoop/hdfs_nn/wait', options.wait_hdfs_nn, conf_dir: options.nn_conf_dir

## Wait Active NN

      @wait.execute
        header: 'Wait Active NN'
        if: options.active_nn_host isnt options.fqdn
        cmd: mkcmd.hdfs @, "hdfs --config #{options.nn_conf_dir} haadmin -getServiceState #{options.active_shortname}"
        code_skipped: 255

## Start

Start the ZKFC daemon. Important, ZKFC should start first on the active
NameNode. You can also start the server manually with the following two
commands:

```
service hadoop-hdfs-zkfc start
su -l hdfs -c "/usr/hdp/current/hadoop-client/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start zkfc"
```

      @service.start
        header: 'Daemon'
        name: 'hadoop-hdfs-zkfc'

## Wait Failover

Ensure a given NameNode is always active and force the failover otherwise.

In order to work properly, the ZKFC daemon must be running and the command must
be executed on the same server as ZKFC.

      # Note, probably we shall wait for the other NameNode to be started and running
      # before attempting to activate it.
      @system.execute
        header: 'Failover'
        cmd: mkcmd.hdfs @, """
        if hdfs --config #{options.nn_conf_dir} haadmin -getServiceState #{options.active_shortname} | grep standby;
        then hdfs --config #{options.nn_conf_dir} haadmin -ns #{options.dfs_nameservices} -failover #{options.standby_shortname} #{options.active_shortname};
        else exit 2; fi
        """
        code_skipped: 2

## Dependencies

    mkcmd = require '../../lib/mkcmd'
