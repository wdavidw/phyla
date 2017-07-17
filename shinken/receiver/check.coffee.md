
# Shinken Receiver Check

    module.exports = header: 'Shinken Receiver Check', label_true: 'CHECKED', label_false: 'SKIPPED', handler: ->
      {receiver} = @config.ryba.shinken

## TCP

      @system.execute
        header: 'TCP'
        cmd: "echo > /dev/tcp/#{@config.host}/#{receiver.config.port}"

## HTTP

      if receiver.ini.use_ssl is '1'
        cmd = "curl -k https://#{@config.host}:#{receiver.config.port}"
      else
        cmd = "curl http://#{@config.host}:#{receiver.config.port}"
      @system.execute
        header: 'HTTP'
        cmd: "#{cmd} | grep OK"
