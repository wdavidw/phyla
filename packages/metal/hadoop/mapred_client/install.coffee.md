
# MapReduce Install

    module.exports = header: 'MapReduce Client Install', handler: ({options}) ->
      version = null

## Register

      @registry.register 'hconfigure', '@rybajs/metal/lib/hconfigure'
      @registry.register 'hdp_select', '@rybajs/metal/lib/hdp_select'
      @registry.register 'hdfs_upload', '@rybajs/metal/lib/hdfs_upload'
      @registry.register ['hdfs','put'], '@rybajs/metal/lib/actions/hdfs/put'

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
        @system.execute
          shy: true
          cmd: """
          hdp-select versions | tail -1
          """
         , (err, {status, stdout}) ->
            throw err if err
            version = stdout.trim()

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
"@rybajs/metal/hadoop/hdfs_dn/layout" module.

      # @hdfs_upload
      #   header: 'HDFS Tarballs'
      #   wait: 60*1000
      #   id: options.hostname
      #   lock: '/tmp/ryba-mapreduce.lock'
      #   krb5_user: options.hdfs_krb5_user
      @call
        header: 'HDFS Tarballs'
      , ->
        @hdfs.put
          header: 'HDFS Tarballs'
          source: '/usr/hdp/current/hadoop-client/mapreduce.tar.gz'
          target: "/hdp/apps/#{version}/mapreduce/mapreduce.tar.gz"
          nn_url: options.nn_url
          krb5_user: options.hdfs_krb5_user
          mode: '444'

## Ulimit

Increase ulimit for the MapReduce user. The HDP package create the following
files:

```bash
cat /etc/security/limits.d/mapred.conf
mapred    - nofile 32768
mapred    - nproc  65536
```

Note, a user must re-login for those changes to be taken into account. See
the "@rybajs/metal/hadoop/hdfs" module for additional information.

      @system.limits
        header: 'Ulimit'
        user: options.user.name
      , options.user.limits

## Dependencies

    mkcmd = require '../../lib/mkcmd'
