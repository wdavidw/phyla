
# Shinken Arbiter Check

    module.exports = header: 'Shinken Arbiter Check', handler: (options) ->

## TCP

      @system.execute
        header: 'TCP'
        cmd: "echo > /dev/tcp/#{options.fqdn}/#{options.config.port}"

## HTTP

      if options.config.use_ssl is '1'
        cmd = "curl -k https://#{options.fqdn}:#{options.config.port}"
      else
        cmd = "curl http://#{options.fqdn}:#{options.config.port}"
      @system.execute
        header: 'HTTP'
        cmd: "#{cmd} | grep OK"
