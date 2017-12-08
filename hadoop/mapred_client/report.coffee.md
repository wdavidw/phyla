
# MapReduce Client Report

    module.exports = header: 'MapReduce Client Report', handler: (options) ->
      properties.read ctx.ssh, "#{options.conf_dir}/mapred-site.xml", (err, config) ->
        return next err if err
        ctx.emit 'report',
          key: 'mapreduce.map.memory.mb'
          value: prink.filesize.from.megabytes config['mapreduce.map.memory.mb']
          raw: config['mapreduce.map.memory.mb']
          default: '1536'
          description: 'Larger resource limit for maps.'
        ctx.emit 'report',
          key: 'mapreduce.map.java.opts'
          value: config['mapreduce.map.java.opts']
          default: '-Xmx1024M'
          description: 'Larger heap-size for child jvms of maps.'
        ctx.emit 'report',
          key: 'mapreduce.reduce.memory.mb'
          value: prink.filesize.from.megabytes config['mapreduce.reduce.memory.mb']
          raw: config['mapreduce.reduce.memory.mb']
          default: '3072'
          description: 'Larger resource limit for reduces.'
        ctx.emit 'report',
          key: 'mapreduce.reduce.java.opts'
          value: config['mapreduce.reduce.java.opts']
          default: '-Xmx2560M'
          description: 'Larger heap-size for child jvms of reduces.'
        ctx.emit 'report',
          key: 'mapreduce.task.io.sort.mb'
          value: prink.filesize.from.megabytes config['mapreduce.task.io.sort.mb']
          raw: config['mapreduce.task.io.sort.mb']
          default: '512'
          description: 'Higher memory-limit while sorting data for efficiency.'
        ctx.emit 'report',
          key: 'mapreduce.task.io.sort.factor'
          value: config['mapreduce.task.io.sort.factor']
          default: '100'
          description: 'More streams merged at once while sorting files.'
        ctx.emit 'report',
          key: 'mapreduce.reduce.shuffle.parallelcopies'
          value: config['mapreduce.reduce.shuffle.parallelcopies']
          default: '50'
          description: 'Higher number of parallel copies run by reduces to fetch outputs from very large number of maps.'
        next null, true

## Dependencies

    properties = require '../../lib/properties'
    prink = require 'prink'
