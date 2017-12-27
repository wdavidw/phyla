
# NagVis Install

    module.exports = header: 'NagVis Install', handler: (options) ->

## IPTables

| Service           | Port  | Proto | Parameter       |
|-------------------|-------|-------|-----------------|
|  nagvis           | 50000 |  tcp  |                 |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          chain: 'INPUT', jump: 'ACCEPT', dport: options.port, protocol: 'tcp', state: 'NEW', comment: "NagVis"
        ]
        if: options.iptables

## Packages

      @call header: 'Packages', ->
        @service name: 'php'
        @service name: 'php-common'
        @service name: 'php-pdo'
        @service name: 'php-gd'
        @service name: 'php-mbstring'
        @service name: 'php-mysql'
        # @service name: 'php-php-gettext'
        @service name: 'graphviz-php'

## Install

      @call unless_exec: "[ `cat #{options.install_dir}/version` = #{options.version} ]", header: 'Archive', ->
        @file.download
          source: options.source
          target: "/var/tmp/nagvis-#{options.version}.tar.gz"
        @tools.extract
          source: "/var/tmp/nagvis-#{options.version}.tar.gz"
        @system.chmod
          target: "/var/tmp/nagvis-#{options.version}/install.sh"
          mode: 0o755
        @system.execute
          cmd: """
          cd /var/tmp/nagvis-#{options.version};
          ./install.sh -n #{options.base_dir} -p #{options.install_dir} \
          -l 'tcp:#{options.livestatus_address}' -b mklivestatus -u #{options.httpd_user.name} -g #{options.httpd_group.name} -w /etc/httpd/conf.d -a y -q
          """
        @service.restart
          name: 'httpd'
        @file
          target: "#{options.install_dir}/version"
          content: "#{options.version}"
        @system.remove target: "/var/tmp/nagvis-#{options.version}.tar.gz"
        @system.remove target: "/var/tmp/nagvis-#{options.version}"

      write = ""
      for k, v of options.config
        write += "[#{k}]\n"
        for sk, sv of v
          write += "#{sk}=" + if typeof sv is 'string' then "\"#{sv}\"\n" else "#{sv}\n"
        write += "\n"
      @file
        target: "#{options.install_dir}/etc/options.ini.php"
        content: write
        backup: true

## Dependencies

    glob = require 'glob'
    path = require 'path'
