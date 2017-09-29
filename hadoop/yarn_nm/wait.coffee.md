
# Hadoop Yarn NodeManagers Wait

Wait for the NodeManagers HTTP ports. It supports HTTPS and HA.

    module.exports = header: 'YARN NM Wait', handler: (options) ->

## TCP Addresss

      @connection.wait
        header: 'TCP'
        quorum: 1
        servers: options.tcp

## TCP Localizer Address

      @connection.wait
        header: 'TCP Localizer'
        quorum: 1
        servers: options.tcp_localiser

## Webapp HTTP Adress

      @connection.wait
        header: 'HTTP Webapp'
        quorum: 1
        servers: options.webapp
