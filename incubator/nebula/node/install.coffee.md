
# OpenNebula Node Install

Install OpenNebula on nodes.

    module.exports = header: 'OpenNebula Node Install', handler: (options) ->

## Install

      @call header: 'Packages', ->
        @service
          header: 'opennebula-node-kvm'
          name: 'opennebula-node-kvm'

## Service libvirtd start

      @service.restart
        header: 'Start libvirtd'
        name: 'libvirtd'

## Set SSH key of the admin for password less login

      # @file
      #   header: "Authorized Keys"
      #   target: "/var/lib/one/.ssh/authorized_keys"
      #   mode: "0600"
      #   uid: "oneadmin"
      #   gid: "oneadmin"
      #   eof: true
      # , options.public_key
