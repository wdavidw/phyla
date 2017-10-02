
# Ganglia Monitor

[Ganglia](http://ganglia.sourceforge.net) is a scalable distributed monitoring
system for high-performance computing systems such as clusters and Grids. It is 
based on a hierarchical design targeted at federations of clusters. Ganglia 
Monitor is the agent to be deployed on each of the hosts.

    module.exports = ->
      # 'backup': 'ryba/retired/ganglia/monitor/backup'
      # 'check': 'ryba/retired/ganglia/monitor/check'
      'install': [
        'ryba/retired/ganglia/monitor/install'
        'ryba/retired/ganglia/monitor/start'
      ]
      'start':
        'ryba/retired/ganglia/monitor/start'
      # 'status': 'ryba/retired/ganglia/monitor/status'
      'stop':
        'ryba/retired/ganglia/monitor/stop'
