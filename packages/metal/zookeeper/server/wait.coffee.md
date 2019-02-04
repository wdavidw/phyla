
# Zookeeper Server Wait

Wait for all ZooKeeper server to listen.

    module.exports = header: 'ZooKeeper Server Wait', handler: ({options}) ->
      @connection.wait
        servers: options.tcp
        quorum: true
