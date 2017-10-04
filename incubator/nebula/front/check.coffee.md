
# OpenNebula Front Check

    module.exports = header: 'OpenNebula Front Check', handler: (options) ->
      @system.execute
        cmd: """
        su -l oneadmin -c 'oneuser show'
        """
