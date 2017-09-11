
# Hadoop HDFS JournalNode Configure

The JournalNode uses properties define inside the "ryba/hadoop/hdfs" module. It
also declare a new property "dfs.journalnode.edits.dir".

*   `hdp.hdfs.site['dfs.journalnode.edits.dir']` (string)   
    The directory where the JournalNode will write transaction logs, default
    to "/var/run/hadoop-hdfs/journalnode\_edit\_dir"

Example:

```json
{
  "site": {
    "dfs.journalnode.edits.dir": "/var/run/hadoop-hdfs/journalnode\_edit\_dir"
  }
}
```

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/hadoop/hdfs_jn', ['ryba', 'hdfs', 'jn'], require('nikita/lib/misc').merge require('.').use,
        iptables: key: ['iptables']
        krb5_client: key: ['krb5_client']
        java: key: ['java']
        hadoop_core: key: ['ryba']
        hdfs_jn: key: ['ryba', 'hdfs', 'jn']
        zookeeper_server: key: ['ryba', 'zookeeper']
      @config.ryba ?= {}
      @config.ryba.hdfs ?= {}
      @config.ryba.hdfs.jn ?= {}
      options = @config.ryba.hdfs.jn = service.options

## Environment

      options.pid_dir ?= service.use.hadoop_core.options.hdfs.pid_dir
      options.log_dir ?= service.use.hadoop_core.options.hdfs.log_dir
      options.conf_dir ?= '/etc/hadoop-hdfs-journalnode/conf'
      options.hadoop_opts ?= service.use.hadoop_core.options.hadoop_opts
      # Java
      options.java_home ?= service.use.java.options.java_home
      options.hadoop_heap ?= service.use.hadoop_core.options.hadoop_heap
      # Misc
      options.clean_logs ?= false
      options.iptables ?= service.use.iptables and service.use.iptables.options.action is 'start'

## Identities

      options.hadoop_group = merge {}, service.use.hadoop_core.options.hadoop_group, options.hadoop_group
      options.group = merge {}, service.use.hadoop_core.options.hdfs.group, options.group
      options.user = merge {}, service.use.hadoop_core.options.hdfs.user, options.user

## Configuration

      options.core_site = merge {}, service.use.hadoop_core.options.core_site, options.core_site or {}
      options.hdfs_site ?= {}
      options.hdfs_site['dfs.journalnode.rpc-address'] ?= '0.0.0.0:8485'
      options.hdfs_site['dfs.journalnode.http-address'] ?= '0.0.0.0:8480'
      options.hdfs_site['dfs.journalnode.https-address'] ?= '0.0.0.0:8481'
      options.hdfs_site['dfs.http.policy'] ?= 'HTTPS_ONLY'
      # Recommandation is to ideally have dedicated disks to optimize fsyncs operation
      options.hdfs_site['dfs.journalnode.edits.dir'] ?= ['/var/hdfs/edits']
      options.hdfs_site['dfs.journalnode.edits.dir'] = options.hdfs_site['dfs.journalnode.edits.dir'].join ',' if Array.isArray options.hdfs_site['dfs.journalnode.edits.dir']
      

## Kerberos

      options.krb5 ?= {}
      options.krb5.realm ?= service.use.krb5_client.options.etc_krb5_conf?.libdefaults?.default_realm
      throw Error 'Required Options: "realm"' unless options.krb5.realm
      # options.krb5.admin ?= service.use.krb5_client.options.admin[options.krb5.realm]
      # Kerberos
      # TODO: Principal should be "jn/{host}@{realm}", however, there is
      # no properties to have a separated keytab between jn and spnego principals
      options.hdfs_site['dfs.journalnode.kerberos.internal.spnego.principal'] = "HTTP/_HOST@#{options.krb5.realm }"
      options.hdfs_site['dfs.journalnode.kerberos.principal'] = "HTTP/_HOST@#{options.krb5.realm }"
      options.hdfs_site['dfs.journalnode.keytab.file'] = '/etc/security/keytabs/spnego.service.keytab'

## SSL

      options.ssl = merge {}, service.use.hadoop_core.options.ssl, options.ssl
      options.ssl_server = merge {}, service.use.hadoop_core.options.ssl_server, options.ssl_server or {}
      options.ssl_client = merge {}, service.use.hadoop_core.options.ssl_client, options.ssl_client or {}

## Metrics

      options.hadoop_metrics ?= service.use.hadoop_core.options.hadoop_metrics

## Wait

      options.wait_krb5_client = service.use.krb5_client.options.wait
      options.wait_zookeeper_server = service.use.zookeeper_server[0].options.wait
      options.wait = {}
      options.wait.rpc = for srv in service.use.hdfs_jn
        srv.options.hdfs_site ?= {}
        srv.options.hdfs_site['dfs.journalnode.rpc-address'] ?= '0.0.0.0:8485'
        [_, port] = srv.options.hdfs_site['dfs.journalnode.rpc-address'].split ':'
        host: srv.node.fqdn, port: port

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'
