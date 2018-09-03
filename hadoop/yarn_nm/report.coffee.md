
# Yarn ResourceManager Report

The following values are reported:   
*   Physical memory in MB allocated for containers.   
*   Ratio between virtual memory to physical memory.

    module.exports = header: 'YARN NM Report', handler: ({options}) ->
      config = null
      @call (_, callback) ->
        properties.read @ssh, "#{options.conf_dir}/yarn-site.xml", (err, config) =>
          config = c unless err
          callback err
      @call ->
        @emit 'report',
          key: 'yarn.nodemanager.resource.memory-mb'
          value:  prink.filesize.from.megabytes config['yarn.nodemanager.resource.memory-mb']
          raw: config['yarn.nodemanager.resource.memory-mb']
          default: '8192'
          description: 'Physical memory in MB allocated for containers.'
        @emit 'report',
          key: 'yarn.nodemanager.vmem-pmem-ratio'
          value: config['yarn.nodemanager.vmem-pmem-ratio']
          default: '2.1'
          description: 'Ratio between virtual memory to physical memory.'

## Dependencies

    properties = require '../../lib/properties'
    prink = require 'prink'
