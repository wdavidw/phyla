
# Hadoop YARN Timeline Server Start

Start the Yarn Application History Server. You can also start the server
manually with the following command:

```
service hadoop-yarn-timelineserver start
su -l yarn -c "/usr/hdp/current/hadoop-yarn-timelineserver/sbin/yarn-daemon.sh --config /etc/hadoop/conf start timelineserver"
```

The ATS requires HDFS to be operationnal or an exception is trown: 
"java.lang.IllegalArgumentException: java.net.UnknownHostException: {cluster name}".

    module.exports = header: 'YARN ATS Start', handler: (options) ->

## Wait

Wait for Kerberos and the HDFS NameNode.

      @call 'masson/core/krb5_client/wait', once: true, options.wait_krb5_client
      @call 'ryba/hadoop/hdfs_nn/wait', once: true, options.wait_hdfs_nn, conf_dir: options.conf_dir

## Run

Start the service.

      @service.start
        name: 'hadoop-yarn-timelineserver'
