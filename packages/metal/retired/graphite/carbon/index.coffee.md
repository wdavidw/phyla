
# Graphite Carbon

Graphite Carbon daemons make up the storage backend of a Graphite installation
All of the carbon daemons listen for time-series data and can accept it over a common set of protocols.
However, they differ in what they do with the data once they receive it.

    module.exports = ->
      # 'backup':
      #   '@rybajs/metal/graphite/carbon/backup'
      # 'check':
      #   '@rybajs/metal/graphite/carbon/check'
      'configure':
        '@rybajs/metal/graphite/carbon/configure'
      # 'install':
      #   '@rybajs/metal/graphite/carbon/install'
      # 'start':
      #   '@rybajs/metal/graphite/carbon/start'
      # 'status':
      #   '@rybajs/metal/graphite/carbon/status'
      # 'stop':
      #   '@rybajs/metal/graphite/carbon/stop'
