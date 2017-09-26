
# MongoDB Config Server Check

    module.exports = header: 'MongoDB Config Server Check', label_true: 'CHECKED', handler: (options) ->

## Check

      @system.execute
        header: 'TCP'
        cmd: "echo > /dev/tcp/#{options.fqdn}/#{options.config.net.port}"
