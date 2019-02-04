# Ambari Client

[Ambari-agent][Ambari-agent-install] on hosts enables the ambari server to be
aware of the  hosts where Hadoop will be deployed. The Ambari Server must be 
installed before the agent registration.


    module.exports =
      use:
        java: module: 'masson/commons/java', recommanded: true
        hdf: module: '@rybajs/metal/hdf'
        ambari_repo: module: '@rybajs/metal/ambari/hdfrepo', local: true, implicit: true
        ambari_server: module: '@rybajs/metal/ambari/hdfserver', required: true
      configure:
        '@rybajs/metal/ambari/hdfagent/configure'
      # configure: ->
      #     require('../agent/configure').call @, null, 'ambari_hdfagent'
      commands:
        'install': ->
          options = @config.ryba.ambari.hdfagent
          @call '@rybajs/metal/ambari/agent/install', options
          @call '@rybajs/metal/ambari/agent/start', options
        'start': '@rybajs/metal/ambari/agent/start'
        'stop': '@rybajs/metal/ambari/agent/stop'

[Ambari-agent-install]: https://cwiki.apache.org/confluence/display/AMBARI/Installing+ambari-agent+on+target+hosts
