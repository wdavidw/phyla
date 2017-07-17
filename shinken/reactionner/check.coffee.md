
# Shinken Reactionner Check

    module.exports = header: 'Shinken Reactionner Check', label_true: 'CHECKED', label_false: 'SKIPPED', handler: ->
      {reactionner} = @config.ryba.shinken

## TCP

      @system.execute
        header: 'TCP'
        cmd: "echo > /dev/tcp/#{@config.host}/#{reactionner.config.port}"

## HTTP

      if reactionner.ini.use_ssl is '1'
        cmd = "curl -k https://#{@config.host}:#{reactionner.config.port}"
      else
        cmd = "curl http://#{@config.host}:#{reactionner.config.port}"
      @system.execute
        header: 'HTTP'
        cmd: "#{cmd} | grep OK"
