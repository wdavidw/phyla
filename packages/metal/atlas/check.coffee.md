
# Altas Metadata Server Check

Apache Atlas Needs the following components to be started.

    module.exports = header: 'Atlas Check', handler: (options) ->

      @call '@rybajs/metal/atlas/wait', options.wait

      #TODO: Write Atlas Rest Api Check
