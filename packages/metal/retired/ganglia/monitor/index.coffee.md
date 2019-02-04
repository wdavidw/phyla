
# Ganglia Monitor

[Ganglia](http://ganglia.sourceforge.net) is a scalable distributed monitoring
system for high-performance computing systems such as clusters and Grids. It is 
based on a hierarchical design targeted at federations of clusters. Ganglia 
Monitor is the agent to be deployed on each of the hosts.

    module.exports = ->
      # 'backup': '@rybajs/metal/retired/ganglia/monitor/backup'
      # 'check': '@rybajs/metal/retired/ganglia/monitor/check'
      'install': [
        '@rybajs/metal/retired/ganglia/monitor/install'
        '@rybajs/metal/retired/ganglia/monitor/start'
      ]
      'start':
        '@rybajs/metal/retired/ganglia/monitor/start'
      # 'status': '@rybajs/metal/retired/ganglia/monitor/status'
      'stop':
        '@rybajs/metal/retired/ganglia/monitor/stop'
