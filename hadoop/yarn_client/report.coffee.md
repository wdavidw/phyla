
# Yarn ResourceManager Report


    module.exports = header: 'YARN Client Report', label_true: 'INFO', handler: (options) ->
      config = null
      @call (_, callback)
        properties.read @ssh, "#{options.conf_dir}/yarn-site.xml", (err, c) ->
          config = c unless err
        callback err
      @call ->
        @emit 'report',
          key: 'yarn.app.mapreduce.am.resource.mb'
          value:  prink.filesize.from.megabytes config['yarn.app.mapreduce.am.resource.mb']
          raw: config['yarn.app.mapreduce.am.resource.mb']
          default: '1536'
          description: 'Memory needed by the MR AppMaster (recommandation: 2 * RAM-per-Container).'
        @emit 'report',
          key: 'yarn.app.mapreduce.am.command-opts'
          value: config['yarn.app.mapreduce.am.command-opts']
          default: '-Xmx1024m'
          description: 'Java opts for the MR App Master (recommandation: 0.8 * 2 * RAM-per-Container).'
        next null, true

## Dependencies

    # mkcmd = require '../../lib/mkcmd'
    properties = require '../../lib/properties'
    prink = require 'prink'
