
# Druid Tranquility Install

    module.exports = header: 'Druid Tranquility Install', handler: (options) ->

## IPTables

| Service           | Port | Proto    | Parameter                   |
|-------------------|------|----------|-----------------------------|
| Druid Tranquility | 8200 | tcp/http |                             |

      @tools.iptables
        header: 'IPTables'
        if: options.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: 8200, protocol: 'tcp', state: 'NEW', comment: "Druid Tranquility" }
        ]

## Identities

By default, the "zookeeper" package create the following entries:

```bash
cat /etc/passwd | grep druid
druid:x:2435:2435:druid User:/var/lib/druid:/bin/bash
cat /etc/group | grep druid
druid:x:2435:
```

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Packages

Download and unpack the release archive.

      @file.download
        header: 'Packages'
        source: "#{options.source}"
        target: "/var/tmp/#{path.basename options.source}"
      # TODO, could be improved
      # current implementation prevent any further attempt if download status is true and extract fails
      @tools.extract
        source: "/var/tmp/#{path.basename options.source}"
        target: '/opt'
        if: -> @status -1
      @system.link
        source: "/opt/tranquility-distribution-#{options.version}"
        target: "#{options.dir}"
      @system.execute
        cmd: """
        if [ $(stat -c "%U" /opt/tranquility-distribution-#{options.version}) == '#{options.user.name}' ]; then exit 3; fi
        chown -R #{options.user.name}:#{options.group.name} /opt/tranquility-distribution-#{options.version}
        """
        code_skipped: 3

## Dependencies

    path = require 'path'
