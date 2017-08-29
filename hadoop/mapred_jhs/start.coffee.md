
# MapReduce JobHistoryServer (JHS) Start

Start the MapReduce Job History Server.

It is recommended but not required to start the JHS server before the Resource
Manager. If started after after, the ResourceManager will print a message in the
log file complaining it cant reach the JSH server (default port is "10020").

    module.exports = header: 'MapReduce JHS Start', label_true: 'STARTED', handler: (options) ->

## Wait

Wait for the DataNode and NameNode to be started to fetch all history.

      @call once: true, 'ryba/hadoop/hdfs_nn/wait', options.wait_hdfs_nn, conf_dir: options.conf_dir

## Service

You can also start the server manually with the following command:

```
service hadoop-mapreduce-historyserver start
systemctl start hadoop-mapreduce-historyserver
su -l mapred -c "/usr/hdp/current/hadoop-mapreduce-historyserver/sbin/mr-jobhistory-daemon.sh --config /etc/hadoop-mapreduce-historyserver/conf start historyserver"
```

      @service.start
        name: 'hadoop-mapreduce-historyserver'
