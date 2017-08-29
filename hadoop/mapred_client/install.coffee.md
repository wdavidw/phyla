
# MapReduce Install

    module.exports = header: 'MapReduce Client Install', handler: (options) ->

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'
      @registry.register 'hdp_select', 'ryba/lib/hdp_select'
      @registry.register 'hdfs_upload', 'ryba/lib/hdfs_upload'

## IPTables

| Service    | Port        | Proto | Parameter                                   |
|------------|-------------|-------|---------------------------------------------|
| mapreduce  | 59100-59200 | http  | yarn.app.mapreduce.am.job.client.port-range |


IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      jobclient = options.mapred_site['yarn.app.mapreduce.am.job.client.port-range']
      jobclient = jobclient.replace '-', ':'
      @tools.iptables
        header: 'IPTables'
        if: options.iptables
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: jobclient, protocol: 'tcp', state: 'NEW', comment: "MapRed Client Range" }
        ]

## Identities

      @system.group header: 'Group', options.hadoop_group
      @system.user header: 'User', options.user

## Service

      @call header: 'Packages', ->
        @service
          name: 'hadoop-mapreduce'
        @hdp_select
          name: 'hadoop-client'

      @hconfigure
        header: 'Configuration'
        target: "#{options.conf_dir}/mapred-site.xml"
        source: "#{__dirname}/../resources/mapred-site.xml"
        local: true
        properties: options.mapred_site
        backup: true
        uid: options.user.name
        gid: options.group.name

## HDFS Tarballs

Upload the MapReduce tarball inside the "/hdp/apps/$version/mapreduce"
HDFS directory. Note, the parent directories are created by the
"ryba/hadoop/hdfs_dn/layout" module.

      @hdfs_upload
        header: 'HDFS Tarballs'
        wait: 60*1000
        source: '/usr/hdp/current/hadoop-client/mapreduce.tar.gz'
        target: '/hdp/apps/$version/mapreduce/mapreduce.tar.gz'
        id: options.hostname
        lock: '/tmp/ryba-mapreduce.lock'

## Ulimit

Increase ulimit for the MapReduce user. The HDP package create the following
files:

```bash
cat /etc/security/limits.d/mapred.conf
mapred    - nofile 32768
mapred    - nproc  65536
```

Note, a user must re-login for those changes to be taken into account. See
the "ryba/hadoop/hdfs" module for additional information.

      @system.limits
        header: 'Ulimit'
        user: options.user.name
      , options.user.limits

## Dependencies

    mkcmd = require '../../lib/mkcmd'
