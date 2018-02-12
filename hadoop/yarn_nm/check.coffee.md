
# YARN NodeManager Check

    module.exports = header: 'YARN NM Check', handler: (options) ->

## TCP Addresss

      @connection.assert
        header: 'TCP'
        # quorum: 1
        servers: options.wait.tcp_local
        retry: 10
        sleep: 3000

## TCP Localizer Address

      @connection.assert
        header: 'TCP Localizer'
        # quorum: 1
        servers: options.wait.tcp_local_localiser
        retry: 3
        sleep: 3000

## Webapp HTTP Adress

      @connection.assert
        header: 'HTTP Webapp'
        # quorum: 1
        servers: options.wait.webapp_local
        retry: 3
        sleep: 3000

      @call header: 'FS Permissions', ->
        log_dirs = options.yarn_site['yarn.nodemanager.log-dirs'].split ','
        local_dirs = options.yarn_site['yarn.nodemanager.local-dirs'].split ','
        cmds = []
        for dir in log_dirs then cmds.push cmd: "su -l #{options.user.name} -c 'ls -l #{dir}'"
        for dir in local_dirs then cmds.push cmd: "su -l #{options.user.name} -c 'ls -l #{dir}'"
        @system.execute cmds
