
# OpenTSDB Check

    module.exports = header: 'OpenTSDB Check', handler: (options) ->

## Wait

      @call once: true, '@rybajs/metal/opentsdb/wait', options.wait_hbase_master

## Check HTTP

      @system.execute
        header: 'Check HTTP'
        cmd: "curl http://#{options.fqdn}:#{options.config['tsd.network.port']}"

## Check HTTP API

      @call header: 'Check HTTP API', (_, callback) ->
        date = Date.now()
        put = JSON.stringify
          metric: 'ryba.test'
          timestamp: date
          value: 42
          tags: api: 'http', host: options.fqdn
        get = JSON.stringify
          start: date-100
          # set end time manually to not have the opentsdb'server default time
          end: date+100
          queries: [
            aggregator: 'count'
            metric: 'ryba.test'
            tags: api: 'http', host: options.fqdn
          ]
        @system.execute
          cmd: """
          curl --fail -X POST -d '#{put}' http://#{options.fqdn}:#{options.config['tsd.network.port']}/api/put
          """
        @system.execute
          # Waiting 2 secs. Opentsdb is not consistent
          cmd: """
          sleep 2;
          curl --fail -X POST -d '#{get}' http://#{options.fqdn}:#{options.config['tsd.network.port']}/api/query
          """
        , (err, executed, stdout, stderr) ->
          [result] = JSON.parse stdout
          throw Error "New key 'ryba.test' not found" unless Object.keys(result.dps).length > 0
        @next callback
