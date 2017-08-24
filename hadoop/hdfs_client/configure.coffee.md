
# Hadoop HDFS Client Configure

    module.exports = ->
      service = migration.call @, service, 'ryba/hadoop/hdfs_client', ['ryba', 'hdfs_client'], require('nikita/lib/misc').merge require('.').use,
        java: key: ['java']
        test_user: key: ['ryba', 'test_user']
        hadoop_core: key: ['ryba']
        hdfs_dn: key: ['ryba', 'hdfs', 'dn']
        hdfs_nn: key: ['ryba', 'hdfs', 'nn']
      options = @config.ryba.hdfs_client = service.options

## Identities

      options.group ?= merge {}, options.group or {}, service.use.hadoop_core.options.hdfs.group
      options.user ?= merge {}, options.user or {}, service.use.hadoop_core.options.hdfs.user

## Environment

      # Layout
      options.conf_dir ?= '/etc/hadoop/conf'
      # Java
      options.java_home ?= service.use.java.options.java_home
      options.hadoop_heap ?= service.use.hadoop_core.options.hadoop_heap
      options.hadoop_opts ?= service.use.hadoop_core.options.hadoop_opts
      options.hadoop_client_opts ?= service.use.hadoop_core.options.hadoop_client_opts
      # Misc
      options.hostname = service.node.hostname

## Configuration

      options.core_site = merge {}, service.use.hadoop_core.options.core_site, options.core_site or {}
      options.site ?= {}
      options.site['dfs.http.policy'] ?= 'HTTPS_ONLY'

Since Hadoop 2.6, [SaslRpcClient](https://issues.apache.org/jira/browse/HDFS-7546) check
that targetted server principal matches configured server principal.
To configure cross-realm communication (with distcp) you need to force a bash-like pattern
to match. By default any principal ('*') will be authorized, as cross-realm trust
is already handled by kerberos

      options.site['dfs.namenode.kerberos.principal.pattern'] ?= '*'

## Core Jars

      options.core_jars ?= {}
      for k, v of options.core_jars
        throw Error 'Invalid core_jars source' unless v.source
        v.match ?= "#{k}-*.jar"
        v.filename = path.basename v.source

## SSL
    
      options.ssl = merge {}, service.use.hadoop_core.options.ssl, options.ssl or {}
      options.ssl_client = merge {}, service.use.hadoop_core.options.ssl_client, options.ssl_client or {},
        'ssl.client.truststore.location': "#{options.conf_dir}/truststore"

## Import NameNode properties

      for property in [
        'fs.defaultFS'
      ] then options.core_site[property] ?= service.use.hdfs_nn[0].options.core_site[property]
      for property in [
        'dfs.namenode.kerberos.principal'
        'dfs.namenode.kerberos.internal.spnego.principal'
        'dfs.namenode.kerberos.https.principal'
        'dfs.web.authentication.kerberos.principal'
        'dfs.ha.automatic-failover.enabled'
        'dfs.nameservices'
        'dfs.internal.nameservices'
        'fs.permissions.umask-mode'
      ] then options.site[property] ?= service.use.hdfs_nn[0].options.site[property]
      for property, value of service.use.hdfs_nn[0].options.site
        ok = false
        ok = true if /^dfs\.namenode\.\w+-address/.test property
        ok = true if property.indexOf('dfs.client.failover.proxy.provider.') is 0
        ok = true if property.indexOf('dfs.ha.namenodes.') is 0
        continue unless ok
        options.site[property] ?= value

## Import DataNode properties

      for property in [
        'dfs.datanode.kerberos.principal'
        'dfs.client.read.shortcircuit'
        'dfs.domain.socket.path'
      ] then options.site[property] ?= service.use.hdfs_dn[0].options.site[property]

## Test

      options.test = merge {}, service.use.test_user.options, options.test or {}

## Wait

      options.wait_hdfs_dn = service.use.hdfs_dn[0].options.wait
      options.wait_hdfs_nn = service.use.hdfs_nn[0].options.wait

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'
