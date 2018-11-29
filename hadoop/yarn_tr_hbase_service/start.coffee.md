
# Hadoop YARN Timeline Reader Start

Start the Yarn Application Reader Server. You can also start the server
manually with the following command:

```
service hadoop-yarn-timelinereader start
su -l yarn -c "/usr/hdp/current/hadoop-yarn-timelinereader/sbin/yarn-daemon.sh --config /etc/hadoop/conf start timelinereader"
```

    module.exports = header: 'YARN TR Start', handler: ({options}) ->

## Wait

Wait for Kerberos and the HDFS NameNode.

      @call 'masson/core/krb5_client/wait', once: true, options.wait_krb5_client
      @call 'ryba/hadoop/hdfs_nn/wait', once: true, options.wait_hdfs_nn, conf_dir: options.conf_dir

## Run

Start the service.

      @service.start
        name: 'hadoop-yarn-hbase-master'
      
      @service.start
        name: 'hadoop-yarn-hbase-regionserver'