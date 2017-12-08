
# Zookeeper Server Stop

Stop the Zookeeper server. You can also stop the server manually with one of
the following two commands:

```
service zookeeper-server stop
su - zookeeper -c "export ZOOCFGDIR=/usr/hdp/current/zookeeper-server/conf; export ZOOCFG=zoo.cfg; source /usr/hdp/current/zookeeper-server/conf/zookeeper-env.sh; /usr/hdp/current/zookeeper-server/bin/zkServer.sh stop"
```

The file storing the PID is "/var/run/zookeeper/zookeeper_server.pid".

    module.exports = header: 'ZooKeeper Server Stop', handler: (options) ->

      @service.stop
        header: 'ZooKeeper Server Stop'
        name: 'zookeeper-server'

## Clean Logs

      @system.execute
        header: 'ZooKeeper Server Clean Logs'
        if: options.clean_logs
        cmd: "rm #{options.log_dir}/*"
        code_skipped: 1
