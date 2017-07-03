
# Schema Registry Install

    module.exports = header: 'Schema Registry Install', handler: ->
      {registry} = @config.ryba
      
## Identities

      @system.group header: 'Group', registry.group
      @system.user header: 'User', registry.user

## IPTables

  | Service  | Port | Proto | Parameter                                            |
  |----------|------|-------|------------------------------------------------------|
  | registry | 9080 | http  | registry.config.server.applicationConnectors[0].port |
  | registry | 9090 | http  | registry.config.server.adminConnectors[0].port       |


      rules = []
      for con, i in registry.config.server.applicationConnectors
        rules.push chain: 'INPUT', jump: 'ACCEPT', dport: con.port, protocol: 'tcp', state: 'NEW', comment: "Registry App #{i+1} port"
      for con, i in registry.config.server.adminConnectors
        rules.push chain: 'INPUT', jump: 'ACCEPT', dport: con.port, protocol: 'tcp', state: 'NEW', comment: "Registry Admin #{i+1} port"
      @tools.iptables
        header: 'IPTables'
        if: @config.iptables.action is 'start'
        rules: rules

## Service

      @call header: 'Packages', ->
        @service
          name: 'registry'
        @service.init
          header: 'rc.d'
          target: '/etc/init.d/registry'
          source: "#{__dirname}/resources/registry.j2"
          context: registry: registry
          local: true
          mode: 0o0755

## Layout

      @call header: 'Layout', ->
        @system.mkdir
          target: registry.pid_dir
          uid: registry.user.name
          gid: registry.group.name
        @system.mkdir
          target: registry.log_dir
          uid: registry.user.name
          gid: registry.group.name
        @execute
          cmd: """
          rm -rf /usr/hdf/current/registry/logs
          ln -s #{registry.log_dir} /usr/hdf/current/registry/logs
          """
          unless_exec: '[ -L /usr/hdf/current/registry/logs ]'

## Env

      @file.render
        header: 'Env'
        target: "#{registry.conf_dir}/registry-env.sh"
        source: "#{__dirname}/resources/registry-env.sh.j2"
        context: registry: registry
        local: true
        backup: true

## Configuration

      @file.yaml
        header: 'Registry properties'
        target: "#{registry.conf_dir}/registry.yaml"
        content: registry.config
        backup: true
        eof: true

## Database

      @call header: 'Storage Backend DB', ->
        @db.user registry.db,
          header: 'User'
          database: null
        @db.database registry.db,
          header: 'Database'
          user: registry.db.username
        @system.execute
          header: 'Bootstrap'
          cmd: db.cmd registry.db, """
          use #{registry.db.database};
          source /usr/hdf/current/registry/bootstrap/sql/#{registry.config['storageProviderConfiguration']['properties']['db.type']}/create_tables.sql;
          """
          if: -> @status -1

## Dependencies

    db = require 'nikita/lib/misc/db'
