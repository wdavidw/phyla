
# Hortonworks Smartsense Install

    module.exports = header: 'HST Agent Install', handler: (options) ->

## Wait Server

      @call once:true, 'ryba/smartsense/server/wait'

## Identities

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Packages
Note rmp can only be download from the Hortonworks Support Web UI.

      @file.download
        if: options.source?
        header: 'Download HST Package'
        source: options.source
        target: "#{options.tmp_dir}/smartsense.rpm"
        binary: true
      @system.execute
        header: 'Install HST Package'
        cmd: "rpm -Uvh #{options.tmp_dir}/smartsense.rpm"
        if: -> @status -1

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

## Setup

      @call header: 'Setup Execution', ->
        @file.ini
          header: 'HST Agent ini file'
          target: "#{options.conf_dir}/hst-server.ini"
          content: options.ini
          parse: misc.ini.parse_multi_brackets_multi_lines
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
          cmd: "hst setup-agent  --server=#{options.server_host}"
        @system.execute
          header: 'Remove execution log files'
          shy: true
          cmd: "rm -f #{options.log_dir}/hst-agent.log"
        @system.execute
          cmd: """
          if [ $(stat -c "%U" #{options.user.home}) == '#{options.user.name}' ]; then exit 3; fi
          chown -R #{options.user.name}:#{options.group.name} #{options.user.home}
          """
          code_skipped: [3,1]

## Dependencies

    misc = require '@nikitajs/core/lib/misc'
