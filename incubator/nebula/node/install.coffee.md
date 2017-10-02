
# Open Nebula Node Install

Install Nebula on nodes

    module.exports = header: 'Nebula Node Install', handler: (options) ->

## Add Nebula repositories

      @tools.repo
        if: options.repo.source?
        header: 'Repository'
        source: options.repo.source
        target: options.repo.target
        replace: options.repo.replace
        update: true

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
      #   content: options.server_public_key
      #   target: "/var/lib/one/.ssh/authorized_keys"
      #   mode: "0600"
      #   uid: "oneadmin"
      #   gid: "oneadmin"
      #   eof: true
