
# Collectd

[Collectd]() gathers metrics from various sources, e.g. the operating system, applications,
 logfiles and external devices, and stores this information or makes it available
 over the network.
 
    module.exports =
      deps:
        yum: module: 'masson/core/yum'
      configure:
        '@rybajs/metal/collectd/configure'
      commands:
        'install': [
          '@rybajs/metal/collectd/install'
          '@rybajs/metal/collectd/start'
        ]
        'start':
          '@rybajs/metal/collectd/start'
        'stop':
          '@rybajs/metal/collectd/stop'
