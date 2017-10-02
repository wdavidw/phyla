
# Open Nebula Front Check

    module.exports = header: 'Nebula Front Check', handler: (options) ->
      @system.execute
        cmd: """
        su -l oneadmin -c 'oneuser show'
        """
