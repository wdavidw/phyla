
# Hortonworks Smartsense Server Install

    module.exports = header:'HST Server Install', handler: (options) ->

## Identities

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Packages
Note rmp can only be download from the Hortonworks Support Web UI.

      @file.download
        if: -> options.source?
        header: 'Download HST Package'
        source: options.source
        target: "#{options.tmp_dir}/smartsense.rpm"
        binary: true
      @system.execute
        header: 'Install HST Package'
        cmd: "rpm -Uvh #{options.tmp_dir}/smartsense.rpm"
        if: -> @status -1
      @service.init
        header: 'Init Script'
        target: '/etc/init.d/hst-server'
        source: "#{__dirname}/../resources/hst-server.j2"
        local: true
        mode: 0o0755
        context:
          'pid_dir': options.pid_dir
          'user': options.user.name
      @system.tmpfs
        if: -> (options.store['nikita:system:type'] in ['redhat','centos']) and (options.store['nikita:system:release'][0] is '7')
        mount: options.pid_dir
        perm: '0750'
        uid: options.user.name
        gid: options.group.name

## IPTables

| Service              | Port  | Proto       | Parameter          |
|----------------------|-------|-------------|--------------------|
| Smartsense Server    | 9000  | http        | port               |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'Smartsense server'
        if: options.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.ini['server']['port'], protocol: 'tcp', state: 'NEW', comment: "Smartsense server" }
        ]

## Layout

      @call header: 'Layout Directories', ->
        @system.mkdir
          target: options.log_dir
          uid: options.user.name
          gid: options.group.name
          mode: 0o0755
        @system.mkdir
          target: options.pid_dir
          uid: options.user.name
          gid: options.group.name
          mode: 0o0755
        @system.mkdir
          target: options.conf_dir
          uid: options.user.name
          gid: options.group.name
          mode: 0o0755

## SSL Download

      @call
        header: 'SSL Server'
        if: options.ini['server']['ssl_enabled']
      , ->
        @file.download
          source: options.ssl.cert.source
          local: options.ssl.cert.local
          target: "#{options.conf_dir}/cert.pem"
          uid: options.user.name
          gid: options.group.name
        @file.download
          source: options.ssl.key.source
          local: options.ssl.key.local
          target: "#{options.conf_dir}/key.pem"
          uid: options.user.name
          gid: options.group.name

## Setup

      @call header: 'Setup Execution', ->
        cmd = """
        hst setup -q \
          --accountname=#{options.ini['customer']['account.name']} \
          --smartsenseid=#{options.ini['customer']['options.id']} \
          --email=#{options.ini['customer']['notification.email']} \
          --storage=#{options.ini['server']['storage.dir']} \
          --port=#{options.ini['server']['port']} \
        """
        cmd += """
          --sslCert=#{options.conf_dir}/cert.pem \
          --sslKey=#{options.conf_dir}/key.pem \
          --sslPass=#{options.ssl_pass} \
        """ if options.ini['server']['ssl_enabled']
        cmd += """
          --cluster=#{options.ini['cluster']['name']} \
          #{if options.ini['cluster']['secured'] then '--secured --nostart' else '--nostart'}
        """
        @system.execute
          cmd: cmd
        @file.ini
          header: 'HST Server ini file'
          target: "#{options.conf_dir}/hst-options.ini"
          content: options.ini
          parse: misc.ini.parse_multi_brackets
          stringify: misc.ini.stringify_multi_brackets
          indent: ''
          separator: '='
          comment: ';'
          uid: options.user.name
          gid: options.group.name
          mode: 0o0750
          merge: true
          backup: true
        @system.execute
          cmd: """
          if [ $(stat -c "%U" #{options.conf_dir}/hst-options.ini.bak) == '#{options.user.name}' ]; then exit 3; fi
          chown -R #{options.user.name}:#{options.group.name} #{options.conf_dir}/hst-options.ini.bak
          """
          code_skipped: [3,1]
        @system.execute
          cmd: """
          if [ $(stat -c "%U" #{options.user.home}) == '#{options.user.name}' ]; then exit 3; fi
          chown -R #{options.user.name}:#{options.group.name} #{options.user.home}
          """
          code_skipped: [3,1]
        @call
          if: -> @status -3
        , ->
          @service.stop
            name: 'hst-server'
          @system.execute
            shy: true
            cmd: "rm -f #{options.log_dir}/hst-options.log"
          @service.start
            name: 'hst-server'


## Dependencies

    misc = require '@nikita/core/lib/misc'
