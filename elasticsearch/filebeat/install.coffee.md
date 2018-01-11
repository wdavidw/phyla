
# Filebeat Install

    module.exports = header: 'Filebeat Install', handler: (options) ->

## Install

      @call header: 'Packages', ->
        @file.download
          source: options.source
          target: "/var/tmp/filebeat-#{options.version}.rpm"
        @system.execute
          cmd: "yum localinstall -y --nogpgcheck /var/tmp/filebeat-#{options.version}.rpm"
          unless_exec: "rpm -q --queryformat '%{VERSION}' filebeat | grep '#{options.version}'"
          
## Config

      @call header: 'Configuration', ->
        @file.render
          header: 'filebeat.yml'
          target: "#{options.conf_dir}/filebeat.yml"
          source: "#{__dirname}/../resources/filebeat.yml.j2"
          local: true
          context: options
          # uid: options.user.name
          # gid: options.hadoop_group.name
          mode: 0o644
          backup: true
          # eof: true

## Dependencies

    # mkcmd = require '../lib/mkcmd'
