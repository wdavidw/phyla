
# Shinken Arbiter Check

    module.exports = header: 'Shinken Arbiter Check', label_true: 'CHECKED', label_false: 'SKIPPED', handler: ->
      {arbiter} = @config.ryba.shinken

## TCP

      @system.execute
          header: 'TCP'
          cmd: "echo > /dev/tcp/#{@config.host}/#{arbiter.config.port}"

## HTTP

      if arbiter.ini.use_ssl is '1'
        cmd = "curl -k https://#{@config.host}:#{arbiter.config.port}"
      else
        cmd = "curl http://#{@config.host}:#{arbiter.config.port}"
      @system.execute
        header: 'HTTP'
        cmd: "#{cmd} | grep OK"
