# Ambari Agent Check

Check the installation of the Ambari Agent.

    module.exports = header: 'Ambari Agent Check', handler: ({options}) ->

## Wait

      @call header: 'Package', ->
        @system.execute
          header: 'yum'
          cmd: 'command -v yum'
        @system.execute
          header: 'rpm'
          cmd: 'command -v rpm'
        @system.execute
          header: 'scp'
          cmd: 'command -v scp'
        @system.execute
          header: 'curl'
          cmd: 'command -v curl'
        @system.execute
          header: 'unzip'
          cmd: 'command -v unzip'
        @system.execute
          header: 'tar'
          cmd: 'command -v tar'
        @system.execute
          header: 'wget'
          cmd: 'command -v wget'
        @system.execute
          header: 'wget'
          cmd: 'command -v wget'
        @system.execute
          header: 'which'
          cmd: 'command -v which'
      
      @call header: 'Max Open Files', ->
        @system.execute
          header: 'Soft limit'
          cmd: '[[ `ulimit -Sn` > 1000 ]]'
        @system.execute
          header: 'Hard limit'
          cmd: '[[ `ulimit -Hn` > 1000 ]]'
