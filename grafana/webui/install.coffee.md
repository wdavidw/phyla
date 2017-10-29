
# Prometheus Install

    module.exports = header: 'Grafana WEBUi Install', handler: (options) ->
      rpm_archive = '/tmp/grafana'

## Wait for database to listen

      @call 'ryba/commons/db_admin/wait', once: true, options.wait_db_admin

## Identities

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## IPTables

| Service    | Port  | Proto  | Parameter          |
|------------|-------|--------|--------------------|
| Grafana UI | 3000  | https  | server.http_port  |

      @tools.iptables
        header: 'IPTables'
        if: options.iptables
        rules:
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.ini['server']['http_port'] , protocol: 'tcp', state: 'NEW', comment: "Grafana Port" }

## Packages

      @call
        header: 'Packages'
      , ->
        @service
          name: 'grafana'
        @call
          if_os: name: ['redhat','centos'], version: '7'
        , ->
          @service.init
            source: "#{__dirname}/../resources/grafana-webui-systemd.j2"
            target: '/usr/lib/systemd/system/grafana-webui.service'
            context: options
            mode: 0o0640
            local: true
            eof: true
          @system.tmpfs
            mount: options.run_dir
            uid: options.user.name
            gid: options.group.name
            perm: '0750'
          @service.startup

## Environment

      @file
        header: 'Environment'
        target: "#{options.conf_dir}/grafana-server"
        write: for k, v of options.env
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        backup: true
        eof: true
        mode: 0o0750
        uid: options.user.name
        gid: options.group.name

## SQL Connectors

      @call
        header: 'MySQL Client'
        if: options.db.engine in ['mariadb', 'mysql']
      , ->
        @service
          name: 'mysql'
        @service
          name: 'mysql-connector-java'
      @call
        header: 'Postgres Client'
        if: options.db.engine is 'postgresql'
      , ->
        @service
          name: 'postgresql'
        @service
          name: 'postgresql-jdbc'

## DB

      @call header: 'Grafana DB', ->
        @db.user options.db, database: null,
          header: 'User'
          if: options.db.engine in ['mariadb', 'postgresql', 'mysql']
        @db.database options.db,
          header: 'Database'
          user: options.db.username
          if: options.db.engine in ['mariadb', 'postgresql', 'mysql']
        @db.schema options.db,
          header: 'Schema'
          if: options.db.engine is 'postgresql'
          schema: options.db.schema or options.db.database
          database: options.db.database
          owner: options.db.username

## SSL

      @file.download
        header: 'SSL Cert'
        source: options.ssl.cert.source
        target: options.ini['server']['cert_file']
        local: options.ssl.cert.local
      @file.download
        header: 'SSL Key'
        source: options.ssl.key.source
        target: options.ini['server']['cert_key']
        local: options.ssl.key.local

## Configuration File

      @file.ini
        header: 'Grafana ini'
        target: "#{options.conf_dir}/grafana.ini"
        content: options.ini
        backup: true
        uid: options.user.name
        gid: options.group.name
        mode: 0o0640

## Dependencies

    quote = require 'regexp-quote'
    misc = require 'nikita/lib/misc'
