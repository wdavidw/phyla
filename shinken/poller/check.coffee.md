
# Shinken Poller Check

    module.exports = header: 'Shinken Poller Check', label_true: 'CHECKED', label_false: 'SKIPPED', handler: ->
      {poller} = @config.ryba.shinken

## TCP

      @system.execute
        header: 'TCP'
        cmd: "echo > /dev/tcp/#{@config.host}/#{poller.config.port}"

## HTTP

      if poller.ini.use_ssl is '1'
        cmd = "curl -k https://#{@config.host}:#{poller.config.port}"
      else
        cmd = "curl http://#{@config.host}:#{poller.config.port}"
      @system.execute
        header: 'HTTP'
        cmd: "#{cmd} | grep OK"
