
# WebHCat Check

    module.exports = header: 'WebHCat Check', label_true: 'CHECKED', handler: (options) ->
      # TODO, maybe we could test hive:
      # curl --negotiate -u : -d execute="show+databases;" -d statusdir="test_webhcat" http://front1.hadoop:50111/templeton/v1/hive

## Assert HTTP

      @connection.assert
        header: 'HTTP'
        servers: options.wait.http.filter (server) -> server.host is options.fqdn
        retry: 3
        sleep: 3000

## Check status

      @system.execute
        header: 'Status'
        cmd: mkcmd.test @, """
        if hdfs dfs -test -f #{options.fqdn}-webhcat; then exit 2; fi
        curl -s --negotiate -u : http://#{options.fqdn}:#{options.webhcat_site['templeton.port']}/templeton/v1/status
        hdfs dfs -touchz #{options.fqdn}-webhcat
        """
        code_skipped: 2
      , (err, executed, stdout) ->
        return if err
        return unless executed
        throw Error "WebHCat not started" if JSON.parse(stdout).status isnt 'ok'

## Dependencies

    mkcmd = require '../../lib/mkcmd'
