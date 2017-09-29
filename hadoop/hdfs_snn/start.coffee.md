
# Hadoop HDFS SecondaryNameNode Start

    module.exports = header: 'HDFS SNN Start', handler: ->

## Start Service

Start the HDFS NameNode Server. You can also start the server manually with the
following two commands:

```
service hadoop-hdfs-secondarynamenode start
su -l hdfs -c "/usr/hdp/current/hadoop-client/sbin/hadoop-daemon.sh --config /etc/hadoop/conf --script hdfs start secondarynamenode"
```
  
      @service.start
        name: 'hadoop-hdfs-secondarynamenode'
