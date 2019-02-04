
# Ganglia Collector

Ganglia Collector is the server which recieves data collected on each
host by the Ganglia Monitor agents.

    module.exports =
      configure:
        '@rybajs/metal/retired/ganglia/collector/configure'
      commands: ->
        # 'backup':
        #   '@rybajs/metal/retired/ganglia/collector/backup'
        'check':
          '@rybajs/metal/retired/ganglia/collector/check'
        'install':[
          'masson/core/iptables'
          'masson/commons/httpd'
          '@rybajs/metal/commons/repos'
          '@rybajs/metal/retired/ganglia/collector/install'
          '@rybajs/metal/retired/ganglia/collector/start'
          '@rybajs/metal/retired/ganglia/collector/check'
        ]
        'start':
          '@rybajs/metal/retired/ganglia/collector/start'
        # 'status':
        #   '@rybajs/metal/retired/ganglia/collecto/status'
        'stop':
          '@rybajs/metal/retired/ganglia/collector/stop'
