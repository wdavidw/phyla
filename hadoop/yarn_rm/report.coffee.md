
# Hadoop Yarn ResourceManager Info

## Info Memory

    module.exports = header: 'YARN RM Info Memory', handler: (options) ->
      config = null
      @call (_, callback) ->
        properties.read @ssh, "#{options.conf_dir}/yarn-site.xml", (err, config) =>
          config = c unless err
          callback err
      @call ->
        @emit 'report',
          key: 'yarn.scheduler.minimum-allocation-mb'
          value: prink.filesize.from.megabytes config['yarn.scheduler.minimum-allocation-mb']
          raw: config['yarn.scheduler.minimum-allocation-mb']
          default: '1024'
          description: 'Lower memory allocated in MB for every container request.'
        @emit 'report',
          key: 'yarn.scheduler.maximum-allocation-mb'
          value: prink.filesize.from.megabytes config['yarn.scheduler.maximum-allocation-mb']
          raw: config['yarn.scheduler.maximum-allocation-mb']
          default: '8192'
          description: 'Higher memory allocated in MB for every container request.'

## Dependencies

    properties = require '../../lib/properties'
    prink = require 'prink'
