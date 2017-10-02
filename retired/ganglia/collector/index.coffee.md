
# Ganglia Collector

Ganglia Collector is the server which recieves data collected on each
host by the Ganglia Monitor agents.

    module.exports = ->
      # 'backup':
      #   'ryba/retired/ganglia/collector/backup'
      'configure':
        'ryba/retired/ganglia/collector/configure'
      'check':
        'ryba/retired/ganglia/collector/check'
      'install':[
        'masson/core/iptables'
        'masson/commons/httpd'
        'ryba/commons/repos'
        'ryba/retired/ganglia/collector/install'
        'ryba/retired/ganglia/collector/start'
        'ryba/retired/ganglia/collector/check'
      ]
      'start':
        'ryba/retired/ganglia/collector/start'
      # 'status':
      #   'ryba/retired/ganglia/collecto/status'
      'stop':
        'ryba/retired/ganglia/collector/stop'
