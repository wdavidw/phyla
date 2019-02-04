
# HDFS HttpFS Start

Start the HDFS HttpFS Server.

    module.exports = header: 'HDFS HttpFS Start', handler: ({options}) ->

## Wait

      @call 'masson/core/krb5_client/wait', once: true, options.wait_krb5_client
      @call '@rybajs/metal/hadoop/hdfs_nn/wait', once: true, options.wait_hdfs_nn, conf_dir: options.hdfs_conf_dir

## Service

You can also start the server manually with the following command:

```
service hadoop-httpfs start
servicectl start hadoop-httpfs
su -l httpfs -c '/usr/hdp/current/hadoop-httpfs/sbin/httpfs.sh start'
```

      @service.start
        name: 'hadoop-httpfs'
