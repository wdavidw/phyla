
# Spark History Server Check

    module.exports = header: 'Spark History Server Check', handler: ({options}) ->

      # TODO Juin 2016: get https protocol when available (from 2.0 version)
      @system.execute
        cmd: "curl http://#{options.conf['spark.yarn.historyServer.address']}/api/v1/applications"
      , (err, _, stdout) ->
        throw err if err
        stdout = stdout.trim()
        results = JSON.parse stdout
        throw Error unless results?
