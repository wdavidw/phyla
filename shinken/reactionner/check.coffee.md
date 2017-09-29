
# Shinken Reactionner Check

    module.exports = header: 'Shinken Reactionner Check', handler: ->
      options = @config.ryba.shinken.reactionner

## TCP

      @system.execute
        header: 'TCP'
        cmd: "echo > /dev/tcp/#{@config.host}/#{options.config.port}"

## HTTP

      if options.ini.use_ssl is '1'
        cmd = "curl -k https://#{@config.host}:#{options.config.port}"
      else
        cmd = "curl http://#{@config.host}:#{options.config.port}"
      @system.execute
        header: 'HTTP'
        cmd: "#{cmd} | grep OK"
