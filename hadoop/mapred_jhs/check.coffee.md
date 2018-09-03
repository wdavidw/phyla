

# MapReduce JHS Check

    module.exports = header: 'MapReduce JHS Check ', handler: ({options}) ->

## Wait

Wait for the server to be started before executing the tests.

      @call once: true, 'ryba/hadoop/mapred_jhs/wait', options.wait

## Check HTTP

Check if the JobHistoryServer is started with an HTTP REST command. Once
started, the server take some time before it can correctly answer HTTP request.
For this reason, the "retry" property is set to the high value of "10".

      protocol = if options.mapred_site['mapreduce.jobhistory.http.policy'] is 'HTTP_ONLY' then 'http' else 'https'
      [host, port] = if protocol is 'http'
      then options.mapred_site['mapreduce.jobhistory.webapp.address'].split ':'
      else options.mapred_site['mapreduce.jobhistory.webapp.https.address'].split ':'
      @system.execute
        header: 'HTTP'
        retry: 200
        cmd: mkcmd.test options.test_krb5_user, """
        curl -s --insecure --negotiate -u : #{protocol}://#{host}:#{port}/ws/v1/history/info
        """
        # code_skipped: 2 # doesnt seems to be used
      , (err, obj) ->
        throw err if err
        JSON.parse(obj.stdout).historyInfo.hadoopVersion

## Dependencies

    mkcmd = require '../../lib/mkcmd'
