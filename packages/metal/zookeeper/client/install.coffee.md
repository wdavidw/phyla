
# Zookeeper Client Install

    module.exports = header: 'ZooKeeper Client Install', handler: ({options}) ->

## Register

      @registry.register 'hdp_select', '@rybajs/metal/lib/hdp_select'
      @registry.register ['file', 'jaas'], '@rybajs/metal/lib/file_jaas'

## Users & Groups

By default, the "zookeeper" package create the following entries:

```bash
cat /etc/passwd | grep zookeeper
zookeeper:x:497:498:ZooKeeper:/var/run/zookeeper:/bin/bash
cat /etc/group | grep hadoop
hadoop:x:498:hdfs
```

      @system.group header: "Group #{options.hadoop_group.name}", options.hadoop_group
      @system.group header: "Group #{options.group.name}", options.group
      @system.user header: "User #{options.user.name}", options.user

## Packages

Follow the [HDP recommandations][install] to install the "zookeeper" package
which has no dependency.

      @call header: 'Packages', ->
        @service
          name: 'zookeeper'
        @hdp_select
          name: 'zookeeper-client'

## Kerberos

Create the JAAS client configuration file.

      @file.jaas
        header: 'Kerberos'
        target: "#{options.conf_dir}/zookeeper-client.jaas"
        content: Client:
          useTicketCache: 'true'
        mode: 0o644

## Environment

Generate the "zookeeper-env.sh" file.

      @file
        header: 'Environment'
        target: "#{options.conf_dir}/zookeeper-env.sh"
        content: ("export #{k}=\"#{v}\"" for k, v of options.env).join '\n'
        backup: true
        eof: true
