
# Hadoop metrics

Configure Hadoop metrics. Does not write anyfile.
    
    # migration: lucasbak
    # this module is a helper to isolate hadoop_metrics configuration
    #other module does read only from it
    
    module.exports =
      deps: {}
      configure: (service) ->
        options = service.options

## Configuration
Each provider has two properties:
- `config`, describing the provider and its default values. 
- `properties`, describing the inherited properties
  ```json
    sinks.graphite: 
      properties: {
        "*.sinks.file.filename": "metrics.out"
      },
      config: {
        "server_host": "metrics.metal.ryba",
        "server_port": 2023,
        "class": 'org.apache.hadoop.metrics2.sink.GraphiteSink'
      }
  ```

        options.sinks ?= {}
        options.sinks.file_enabled ?= true
        if options.sinks.file_enabled
          options.sinks.file ?= {}
          options.sinks.file.properties ?= {}
          options.sinks.file.config ?= {}
          options.sinks.file.config.class ?= 'org.apache.hadoop.metrics2.sink.FileSink'
          options.sinks.file.config.filename ?= 'metrics.out'
        # Ganglia Sink
        options.sinks.ganglia_enabled ?= false
        if options.sinks.ganglia_enabled
          options.sinks.ganglia ?= {}
          options.sinks.ganglia.properties ?= {}
          options.sinks.ganglia.config ?= {}
          options.sinks.ganglia.config.class ?= 'org.apache.hadoop.metrics2.sink.ganglia.GangliaSink31'
          options.sinks.ganglia.config.period ?= '10'
          options.sinks.ganglia.config.supportparse ?= 'true' # Setting to "true" helps in reducing bandwith (see "Practical Hadoop Security")
          options.sinks.ganglia.config.slope ?= 'jvm.metrics.gcCount=zero,jvm.metrics.memHeapUsedM=both'
          options.sinks.ganglia.config.dmax ?= 'jvm.metrics.threadsBlocked=70,jvm.metrics.memHeapUsedM=40' # How long a particular value will be retained
        # Graphite Sink
        if options.sinks.graphite_enabled ?= false
          options.sinks.graphite ?= {}
          options.sinks.graphite.properties ?= {}
          options.sinks.graphite.config ?= {}
          options.sinks.graphite.config.class ?= 'org.apache.hadoop.metrics2.sink.GraphiteSink'
          options.sinks.graphite.config.period ?= '10'
          throw Error 'Missing ryba.metrics.sinks.graphite.config.server_host' unless options.sinks.graphite.config.server_host?
          throw Error 'Missing ryba.metrics.sinks.graphite.config.server_port' unless options.sinks.graphite.config.server_port?
          options.sinks.graphite.config ?= {}


## Dependencies

    {merge} = require '@nikitajs/core/lib/misc'
