
# Ambari Client

[Ambari-agent][Ambari-agent-install] on hosts enables the ambari server to be
aware of the  hosts where Hadoop will be deployed. The Ambari Server must be 
installed before the agent registration.

    module.exports =
      deps:
        java: module: '@rybajs/system/java', local: true, recommanded: true
        ambari_server: module: '@rybajs/ambari/server', required: true
        ambari_repo: module: '@rybajs/ambari/repo', local: true, auto: true, implicit: true
        ambari_agent: module: '@rybajs/ambari/agent'
        # local_agent: module: '@rybajs/agent', local: true, required: true
      configure:
        '@rybajs/ambari/agent/configure'
      commands:
        'install': [
          '@rybajs/ambari/agent/install'
          '@rybajs/ambari/agent/start'
        ]
        'start':
          '@rybajs/ambari/agent/start'
        'stop':
          '@rybajs/ambari/agent/stop'

[Ambari-agent-install]: https://cwiki.apache.org/confluence/display/AMBARI/Installing+ambari-agent+on+target+hosts
