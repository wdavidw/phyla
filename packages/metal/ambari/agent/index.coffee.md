
# Ambari Client

[Ambari-agent][Ambari-agent-install] on hosts enables the ambari server to be
aware of the  hosts where Hadoop will be deployed. The Ambari Server must be 
installed before the agent registration.

    module.exports =
      deps:
        java: module: 'masson/commons/java', local: true, recommanded: true
        ambari_server: module: '@rybajs/metal/ambari/server', required: true
        ambari_repo: module: '@rybajs/metal/ambari/repo', local: true, implicit: true
      configure:
        '@rybajs/metal/ambari/agent/configure'
      commands:
        'install': [
          '@rybajs/metal/ambari/agent/install'
          '@rybajs/metal/ambari/agent/start'
        ]
        'start':
          '@rybajs/metal/ambari/agent/start'
        'stop':
          '@rybajs/metal/ambari/agent/stop'

[Ambari-agent-install]: https://cwiki.apache.org/confluence/display/AMBARI/Installing+ambari-agent+on+target+hosts
