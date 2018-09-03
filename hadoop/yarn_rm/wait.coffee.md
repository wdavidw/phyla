
# Hadoop Yarn ResourceManager Wait

Wait for the ResourceManagers RPC and HTTP ports. It supports HTTPS and HA.

    module.exports = header: 'YARN RM Wait', handler: ({options}) ->

## TCP

The RM address isnt listening on port 8050 unless the node is active. This is
the reason why quorum is set to "1".

      @connection.wait
        header: 'TCP'
        quorum: 1
        servers: options.tcp

## Admin

      @connection.wait
        header: 'Admin'
        servers: options.admin

## Webapp Address

      @connection.wait
        header: 'Webapp'
        servers: options.webapp
