
# MongoDB Config Server Install

    module.exports =  header: 'MongoDB Router Install', handler: ({options}) ->

## IPTables

| Service       | Port  | Proto | Parameter       |
|---------------|-------|-------|-----------------|
| Mongod        | 27018 |  tcp  |  configsrv.port |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.config.net.port, protocol: 'tcp', state: 'NEW', comment: "MongoDB Router Server port" }
        ]
        if: options.iptables

## Identities

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

# User limits

      @system.limits
        header: 'User Limits'
        user: options.user.name
      , options.user.limits

## Packages

Install mongod-org-server containing packages for a mongod service. We render the init scripts
in order to rendered configuration file with custom properties.

      @call header: 'Packages'
      , ->
        @service name: 'mongodb-org-mongos'
        @service name: 'mongodb-org-shell'
        @service name: 'mongodb-org-tools'
        @file.render
          if_os: name: ['redhat','centos'], version: '6'
          source: "#{__dirname}/../resources/mongod-router-server.j2"
          target: '/etc/init.d/mongod-router-server'
          context: options
          unlink: true
          mode: 0o0750
          local: true
          eof: true
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            source: "#{__dirname}/../resources/mongod-router-server-redhat-7.j2"
            target: '/usr/lib/systemd/system/mongod-router-server.service'
            context: options
            mode: 0o0640
            local: true
            eof: true
          @system.tmpfs
            mount: options.pid_dir
            uid: options.user.name
            gid: options.group.name
            perm: '0750'

## Layout

Create dir where the mongod-config-server stores its metadata

      @system.mkdir
        header: 'Layout'
        target: '/var/lib/mongodb'
        uid: options.user.name
        gid: options.group.name


## Configure

Configuration file for mongodb config server.

      @call header: 'Configure', ->
        @file.yaml
          target: "#{options.conf_dir}/mongos.conf"
          content: options.config
          merge: false
          uid: options.user.name
          gid: options.group.name
          mode: 0o0750
          backup: true
        @service.stop
          if: -> @status -1
          name: 'mongod-router-server'

## SSL

Mongod service requires to have in a single file the private key and the certificate
with pem file. So we append to the file the private key and certficate.

      @call header: 'SSL', ->
        @file.download
          source: options.ssl.cacert.source
          local: options.ssl.cacert.local
          target: "#{options.conf_dir}/cacert.pem"
          uid: options.user.name
          gid: options.group.name
        @file.download
          source: options.ssl.key.source
          local: options.ssl.key.local
          target: "#{options.conf_dir}/key_file.pem"
          uid: options.user.name
          gid: options.group.name
        @file.download
          source: options.ssl.cert.source
          local: options.ssl.cert.local
          target: "#{options.conf_dir}/cert_file.pem"
          uid: options.user.name
          gid: options.group.name
        @file
          source: "#{options.conf_dir}/cert_file.pem"
          target: "#{options.conf_dir}/key.pem"
          append: true
          backup: true
          eof: true
          uid: options.user.name
          gid: options.group.name
        @file
          source: "#{options.conf_dir}/key_file.pem"
          target: "#{options.conf_dir}/key.pem"
          eof: true
          append: true
          uid: options.user.name
          gid: options.group.name
