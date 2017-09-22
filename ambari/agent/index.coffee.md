
# Ambari Client

[Ambari-agent][Ambari-agent-install] on hosts enables the ambari server to be
aware of the  hosts where Hadoop will be deployed. The Ambari Server must be 
installed before the agent registration.

    module.exports =
      use:
        java: module: 'masson/commons/java', local: true, recommanded: true
        ambari_server: module: 'ryba/ambari/server', required: true
        ambari_repo: module: 'ryba/ambari/repo', local: true, implicit: true
      configure:
        'ryba/ambari/agent/configure'
      # configure: ->
      #     require('./configure').call @, null, 'ambari_agent'
      commands:
        'install': ->
          options = @config.ryba.ambari.agent
          @call 'ryba/ambari/agent/install', options
          @call 'ryba/ambari/agent/start', options
        'start': 'ryba/ambari/agent/start'
        'stop': 'ryba/ambari/agent/stop'

[Ambari-agent-install]: https://cwiki.apache.org/confluence/display/AMBARI/Installing+ambari-agent+on+target+hosts
