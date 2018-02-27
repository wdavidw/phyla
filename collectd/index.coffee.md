
# Collectd

[Collectd]() gathers metrics from various sources, e.g. the operating system, applications,
 logfiles and external devices, and stores this information or makes it available
 over the network.
 
    module.exports =
      deps:
        yum: module: 'masson/core/yum'
      configure:
        'ryba/collectd/configure'
      commands:
        'install': [
          'ryba/collectd/install'
          'ryba/collectd/start'
        ]
        'start':
          'ryba/collectd/start'
        'stop':
          'ryba/collectd/stop'
