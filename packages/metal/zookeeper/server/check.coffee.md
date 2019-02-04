
# Zookeeper Server Check

    module.exports = header: 'ZooKeeper Server Check', handler: ({options}) ->

## Wait

      @call '@rybajs/metal/zookeeper/server/wait', once: true, options.wait

## Check state

      @system.execute
        header: 'Healthy'
        cmd: "nc #{options.fqdn} #{options.config['clientPort']} <<< ruok | grep imok"

## Check Registration

Execute these commands on the ZooKeeper host machine(s).

      cmds = for zookeeper in options.zookeeper_server
        "nc #{zookeeper.fqdn} #{zookeeper.port} <<< conf | sed -n 's/.*serverId=\\(.*\\)/\\1/p'"
      @system.execute
        header: 'Registration'
        cmd: cmds.join ';'
      , (err, data) ->
        return if err
        if options.zookeeper_server.length is 1 # Standalone mode
          unless data.stdout.trim().split('\n').sort().join(',') is '0'
            throw Error "Server is not properly registered"
        else # Replicated mode
          throw Error unless /\d+/.test server for server in data.stdout.trim().split('\n')
          # The following test only pass if all zookeeper servers are started.
          # However, we dont wait for all servers to be started but only a
          # quorum of servers.
          # unless stdout.trim().split('\n').sort().join(',') is [1..cmds.length].join(',')
          #   throw Error "Servers are not properly registered"
