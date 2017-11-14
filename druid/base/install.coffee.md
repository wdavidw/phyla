
# Druid Install

    module.exports = header: 'Druid Base Install', handler: (options) ->

## Register and load

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdfs_mkdir', 'ryba/lib/hdfs_mkdir'

## Identities

By default, the "druid" package create the following entries:

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
        source: options.source
        target: "/var/tmp/#{path.basename options.source}"
      @tools.extract
        heaader: 'Extract'
        unless_exists: "/opt/druid-#{options.version}"
        source: "/var/tmp/#{path.basename options.source}"
        target: '/opt'
      @file.assert
        target: "/opt/druid-#{options.version}"
        if: -> @status -1
      @system.execute
        header: 'Owner'
        cmd: """
        if [ $(stat -c "%U" /opt/druid-#{options.version}) == '#{options.user.name}' ]; then exit 3; fi
        chown -R #{options.user.name}:#{options.group.name} /opt/druid-#{options.version}
        """
        code_skipped: 3
      @system.link
        header: 'Link'
        source: "/opt/druid-#{options.version}"
        target: options.dir

## DB Packages

      @call if: options.db.engine is 'postgresql', ->
        @service header: 'Postsgresql', 'postgresql'
      @call if: options.db.engine is 'mysql', ->
        @service header: 'Mysql', 'mysql'
      @file.download
        header: 'MySQL Ext Packages'
        if: options.db.engine in ['mysql', 'mariadb']
        source: options.source_mysql_extension
        target: "/var/tmp/#{path.basename options.source_mysql_extension}"
      @tools.extract
        header: 'MySQL Ext Extract'
        unless_exists: '/opt/druid/extensions/mysql-metadata-storage'
        source: "/var/tmp/#{path.basename options.source_mysql_extension}"
        target: '/opt/druid/extensions'
      @file.assert
        target: '/opt/druid/extensions/mysql-metadata-storage'
        if: -> @status -1
      @system.execute
        header: 'MySQL Ext Owner'
        cmd: """
        if [ $(stat -c "%U" /opt/druid/extensions/mysql-metadata-storage) == '#{options.user.name}' ]; then exit 3; fi
        chown -R #{options.user.name}:#{options.group.name} /opt/druid/extensions/mysql-metadata-storage
        """
        code_skipped: 3

## Layout

Pid files are stored inside "/var/run/druid" by default.
Log files are stored inside "/var/log/druid" by default.

      @call header: 'Layout', ->
        @system.mkdir
          target: "#{options.pid_dir}"
          uid: "#{options.user.name}"
          gid: "#{options.group.name}"
        @system.link
          target: "#{options.dir}/var/druid/pids"
          source: "#{options.pid_dir}"
        @system.mkdir
          target: "#{options.log_dir}"
          uid: "#{options.user.name}"
          gid: "#{options.group.name}"
          parent: true
        @system.link
          source: "#{options.log_dir}"
          target: "#{options.dir}/log"

## Kerberos

Create a service principal for this NameNode. The principal is named after
"nn/{fqdn}@{realm}".

      @krb5.addprinc options.krb5.admin,
        header: 'Kerberos Admin Principal'
        principal: "#{options.krb5_user.principal}"
        password: "#{options.krb5_user.password}"
        randkey: true
        uid: options.user.name
        gid: options.group.name
        mode: 0o0600
      @krb5.addprinc options.krb5.admin,
        header: 'Kerberos Service Principal'
        principal: "#{options.krb5_service.principal}"
        keytab: "#{options.krb5_service.keytab}"
        randkey: true
        uid: "#{options.user.name}"
        gid: "#{options.group.name}"
        mode: 0o0600

## Cron-ed Kinit

Druid has no mechanism to renew its keytab. For that, we use a cron daemon
We then ask a first TGT.

      @cron.add
        header: 'Cron-ed kinit'
        cmd: "/usr/bin/kinit #{options.krb5_service.principal} -kt #{options.krb5_service.keytab}"
        when: '0 */9 * * *'
        user: options.user.name
        exec: true

## Database

      @db.user options.db, database: null, header: 'DB User',
        if: options.db.engine in ['mysql', 'mariadb', 'postgresql']
      @db.database options.db, header: 'Database',
        if: options.db.engine in ['mysql', 'mariadb', 'postgresql']
        user: options.db.username

## Configuration

Configure deep storage.

      @file.properties
        header: 'Runtime'
        target: '/opt/druid/conf/druid/_common/common.runtime.properties'
        content: options.common_runtime
        backup: true
      @system.copy
        header: 'Core Site'
        target: "/opt/druid/conf/druid/_common/core-site.xml"
        source: "#{options.hadoop_conf_dir}/core-site.xml"
      @system.copy
        header: 'HDFS Site'
        target: "/opt/druid/conf/druid/_common/hdfs-site.xml"
        source: "#{options.hadoop_conf_dir}/hdfs-site.xml"
      @hconfigure
        header: 'YARN Site'
        target: "/opt/druid/conf/druid/_common/yarn-site.xml"
        source: "#{options.hadoop_conf_dir}/yarn-site.xml"
        transform: (properties) ->
          if properties['yarn.resourcemanager.ha.rm-ids']
            [id] = properties['yarn.resourcemanager.ha.rm-ids'].split ','
            properties['yarn.resourcemanager.address'] = properties["yarn.resourcemanager.address.#{id}"]
          properties
      @hconfigure
        header: 'MapRed Site'
        target: "/opt/druid/conf/druid/_common/mapred-site.xml"
        source: "#{options.hadoop_conf_dir}/mapred-site.xml"
        transform: (properties) ->
          classpath = properties['mapreduce.application.classpath'].split ','
          jar_validation = "/opt/druid/lib/validation-api-1.1.0.Final.jar"
          classpath.push jar_validation unless jar_validation in classpath
          properties['mapreduce.application.classpath'] = classpath.join ','
          properties
      @hdfs_mkdir
        header: 'HDFS Segments'
        target: '/apps/druid/segments'
        user: "#{options.user.name}"
        group: "#{options.group.name}"
        mode: 0o0750
        krb5_user: options.hdfs_krb5_user
      @hdfs_mkdir
        header: 'HDFS Index Logs'
        target: '/apps/druid/indexing-logs'
        user: "#{options.user.name}"
        group: "#{options.group.name}"
        mode: 0o0750
        krb5_user: options.hdfs_krb5_user
      @hdfs_mkdir
        header: 'HDFS User Home'
        target: "/user/#{options.user.name}"
        user: "#{options.user.name}"
        group: "#{options.group.name}"
        mode: 0o0750
        krb5_user: options.hdfs_krb5_user

## Dependencies

    db = require 'nikita/lib/misc/db'
    path = require 'path'
