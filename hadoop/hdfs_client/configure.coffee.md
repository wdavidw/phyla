
# Hadoop HDFS Client Configure

    module.exports = (service) ->
      options = service.options

## Identities

      options.group = merge {}, service.deps.hadoop_core.options.hdfs.group, options.group
      options.user = merge {}, service.deps.hadoop_core.options.hdfs.user, options.user

## Environment

      # Layout
      options.conf_dir ?= service.deps.hadoop_core.options.conf_dir
      # Java
      options.java_home ?= service.deps.java.options.java_home
      options.hadoop_heap ?= service.deps.hadoop_core.options.hadoop_heap
      options.hadoop_opts ?= service.deps.hadoop_core.options.hadoop_opts
      options.hadoop_client_opts ?= service.deps.hadoop_core.options.hadoop_client_opts
      # Misc
      options.hostname = service.node.hostname

## Kerberos

      # Kerberos HDFS Admin Principal
      options.krb5_user ?= service.deps.hadoop_core.options.hdfs.krb5_user
      # Kerberos Test Principal
      options.test_krb5_user ?= service.deps.test_user.options.krb5.user

## Configuration

      options.core_site = merge {}, service.deps.hadoop_core.options.core_site, options.core_site or {}
      options.hdfs_site ?= {}
      options.hdfs_site['dfs.http.policy'] ?= 'HTTPS_ONLY'

Since Hadoop 2.6, [SaslRpcClient](https://issues.apache.org/jira/browse/HDFS-7546) check
that targetted server principal matches configured server principal.
To configure cross-realm communication (with distcp) you need to force a bash-like pattern
to match. By default any principal ('*') will be authorized, as cross-realm trust
is already handled by kerberos

      options.hdfs_site['dfs.namenode.kerberos.principal.pattern'] ?= '*'

## Core Jars

      options.core_jars ?= {}
      for k, v of options.core_jars
        throw Error 'Invalid core_jars source' unless v.source
        v.match ?= "#{k}-*.jar"
        v.filename = path.basename v.source

## SSL
    
      options.ssl = merge {}, service.deps.hadoop_core.options.ssl, options.ssl
      options.ssl_client = merge {}, service.deps.hadoop_core.options.ssl_client, options.ssl_client or {},
        'ssl.client.truststore.location': "#{options.conf_dir}/truststore"

## Import NameNode properties

      for property in [
        'fs.defaultFS'
      ] then options.core_site[property] ?= service.deps.hdfs_nn[0].options.core_site[property]
      for property in [
        'dfs.namenode.kerberos.principal'
        'dfs.namenode.kerberos.internal.spnego.principal'
        'dfs.namenode.kerberos.https.principal'
        'dfs.web.authentication.kerberos.principal'
        'dfs.ha.automatic-failover.enabled'
        'dfs.nameservices'
        'dfs.internal.nameservices'
        'fs.permissions.umask-mode'
      ] then options.hdfs_site[property] ?= service.deps.hdfs_nn[0].options.hdfs_site[property]
      for property, value of service.deps.hdfs_nn[0].options.hdfs_site
        ok = false
        ok = true if /^dfs\.namenode\.\w+-address/.test property
        ok = true if property.indexOf('dfs.client.failover.proxy.provider.') is 0
        ok = true if property.indexOf('dfs.ha.namenodes.') is 0
        continue unless ok
        options.hdfs_site[property] ?= value

## Import DataNode properties

      for property in [
        'dfs.datanode.kerberos.principal'
        'dfs.client.read.shortcircuit'
        'dfs.domain.socket.path'
      ] then options.hdfs_site[property] ?= service.deps.hdfs_dn[0].options.hdfs_site[property]

## Log4j

      options.log4j = merge {}, service.deps.log4j?.options, options.log4j
      options.log4j.hadoop_root_logger ?= 'INFO,RFA'
      options.log4j.hadoop_security_logger ?= 'INFO,RFAS'
      options.log4j.hadoop_audit_logger ?= 'INFO,RFAAUDIT'

## Test

      options.test = merge {}, service.deps.test_user.options, options.test or {}

## Wait

      options.wait_hdfs_dn = service.deps.hdfs_dn[0].options.wait
      options.wait_hdfs_nn = service.deps.hdfs_nn[0].options.wait

## Dependencies

    {merge} = require 'nikita/lib/misc'
