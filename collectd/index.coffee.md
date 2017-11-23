
# Collectd

[Collectd]() gathers metrics from various sources, e.g. the operating system, applications,
 logfiles and external devices, and stores this information or makes it available
 over the network.
 
    module.exports =
      use:
        yum: module: 'masson/core/yum'
      configure:
        'ryba/collectd/configure'
      commands:
        install: ->
          options  = @config.ryba.collectd
          @call 'ryba/collectd/install', options
          @call 'ryba/collectd/start', options
        start: ->
          options  = @config.ryba.collectd
          @call 'ryba/collectd/start', options
        stop: ->
          options  = @config.ryba.collectd
          @call 'ryba/collectd/stop', options
