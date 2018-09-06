
# ZooKeeper Server Backup

The latest snapshot and the transaction log from the time of the snapshot is
enough to recover to current state. To provide additionnal garanties, the
default configuration backup the last 3 snapshots(in case of corruption of the
latest snap) and the transaction logs from the timestamp corresponding to the
earliest snapshot.

Execute `./bin/ryba backup -m ryba/zookeeper/server` to run this module.

    module.exports = header: 'ZooKeeper Server Backup', handler: ({options}) ->
      now = Math.floor Date.now() / 1000

## Compress the data directory

ZooKeeper stores its data in a data directory and its transaction log in a
transaction log directory. By default these two directories are the same.

TODO: Add the backup facility

      @system.execute
        header: 'Data'
        cmd: """
        tar czf /var/tmp/ryba-zookeeper-data-#{now}.tgz -C #{options.config.dataDir} .
        """
      @system.execute
        header: 'Now'
        cmd: """
        tar czf /var/tmp/ryba-zookeeper-log-#{now}.tgz -C #{options.config.dataLogDir} .
        """
        if: options.config.dataLogDir

## Purge Transaction Logs

      @system.execute
        header: 'Purge Transaction Logs'
        cmd: """
        java -cp /usr/hdp/current/zookeeper-server/zookeeper.jar:/usr/hdp/current/zookeeper-server/lib/*:/usr/hdp/current/zookeeper-server/conf \
          org.apache.zookeeper.server.PurgeTxnLog \
          #{options.config.dataLogDir or ''} #{options.config.dataDir} -n #{options.retention}
        """

## Resources

*   [ZooKeeper Data File Management][data_file]
*   [ZooKeeper Maintenance][maintenance]
*   [Cloudera recommandations][cloudera]

[data_file]: http://zookeeper.apache.org/doc/current/zookeeperAdmin.html#sc_dataFileManagement
[maintenance]: http://zookeeper.apache.org/doc/current/zookeeperAdmin.html#sc_maintenance
[cloudera]: http://www.cloudera.com/content/cloudera/en/documentation/cdh4/latest/CDH4-Installation-Guide/cdh4ig_topic_21_4.html
