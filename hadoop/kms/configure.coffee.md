
# Hadoop KMS Configure

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/hadoop/kms', ['ryba', 'kms'], require('nikita/lib/misc').merge require('.').use,
        iptables: key: ['iptables']
        java: key: ['java']
        zookeeper_server: key: ['ryba', 'zookeeper']
        hadoop_core: key: ['ryba']
      @config.ryba ?= {}
      options = @config.ryba.kms ?= {}

## Identities

      options.group = name: options.group if typeof options.group is 'string'
      options.group ?= {}
      options.group.name ?= 'kms'
      options.group.system ?= true
      options.user = name: options.user if typeof options.user is 'string'
      options.user ?= {}
      options.user.name ?= 'kms'
      options.user.system ?= true
      options.user.comment ?= 'Hadoop KMS User'
      options.user.home ?= "/var/lib/#{options.user.name}"
      options.user.groups ?= ['hadoop']
      options.user.gid ?= options.group.name

## layout

      options.pid_dir ?= '/var/run/hadoop-kms'
      options.conf_dir ?= '/etc/hadoop-kms/conf'
      options.log_dir ?= '/var/log/hadoop-kms'

## Environment

      options.http_port ?= 16000
      options.admin_port ?= 16001
      options.max_threads ?= 1000
      options.iptables ?= service.use.iptables and service.use.iptables.options.action is 'start'

## Configuration

      options.kms_site ?= {}

## Cache

KMS caches keys for short period of time to avoid excessive hits to the
underlying key provider.

      options.kms_site['hadoop.kms.cache.enable'] ?= 'true'
      options.kms_site['hadoop.kms.cache.timeout.ms'] ?= '600000'

## Aggregated Audit logs

Audit logs are aggregated for API accesses to the GET_KEY_VERSION,
GET_CURRENT_KEY, DECRYPT_EEK, GENERATE_EEK operations.

Entries are grouped by the (user,key,operation) combined key for a configurable
aggregation interval after which the number of accesses to the specified
end-point by the user for a given key is flushed to the audit log.

The Aggregation interval is configured via the property :

      options.kms_site['hadoop.kms.current.key.cache.timeout.ms'] ?= '30000'

##  Delegation Token Configuration

KMS delegation token secret manager can be configured with the following properties:

      # How often the master key is rotated, in seconds. Default value 1 day.
      options.kms_site['hadoop.kms.authentication.delegation-token.update-interval.sec'] ?= '86400'
      # Maximum lifetime of a delagation token, in seconds. Default value 7 days.
      options.kms_site['hadoop.kms.authentication.delegation-token.max-lifetime.sec'] ?= '604800'
      # Renewal interval of a delagation token, in seconds. Default value 1 day.
      options.kms_site['hadoop.kms.authentication.delegation-token.renew-interval.sec'] ?= '86400'
      # Scan interval to remove expired delegation tokens.
      options.kms_site['hadoop.kms.authentication.delegation-token.removal-scan-interval.sec'] ?= '3600'

## HTTP Authentication Signature

      # zookeeper_quorum = for srv in service.use.zookeeper_server then "#{srv.node.fqdn}:#{srv.options.port}"
      # options.kms_site['hadoop.kms.authentication.signer.secret.provider'] ?= 'zookeeper'
      # options.kms_site['hadoop.kms.authentication.signer.secret.provider.zookeeper.path'] ?= '/hadoop-kms/hadoop-auth-signature-secret'
      # options.kms_site['hadoop.kms.authentication.signer.secret.provider.zookeeper.connection.string'] ?= "#{zookeeper_quorum}"
      # options.kms_site['hadoop.kms.authentication.signer.secret.provider.zookeeper.auth.type'] ?= 'kerberos'
      # options.kms_site['hadoop.kms.authentication.signer.secret.provider.zookeeper.kerberos.keytab'] ?= "#{options.conf_dir}/kms.keytab"
      # options.kms_site['hadoop.kms.authentication.signer.secret.provider.zookeeper.kerberos.principal'] ?= 'kms/#{@config.host}@{realm}'

## Access Control

KMS ACLs configuration are defined in the KMS /etc/hadoop-kms/kms-acls.xml
configuration file. This file is hot-reloaded when it changes.

KMS supports both fine grained access control as well as blacklist for kms
operations via a set ACL configuration properties.

A user accessing KMS is first checked for inclusion in the Access Control List
for the requested operation and then checked for exclusion in the Black list for
the operation before access is granted.

      options.acls ?= {}
      options.acls['hadoop.kms.acl.CREATE'] ?= '*'
      options.acls['hadoop.kms.blacklist.CREATE'] ?= 'hdfs'
      options.acls['hadoop.kms.acl.DELETE'] ?= '*'
      options.acls['hadoop.kms.blacklist.DELETE'] ?= 'hdfs'
      options.acls['hadoop.kms.acl.ROLLOVER'] ?= '*'
      options.acls['hadoop.kms.blacklist.ROLLOVER'] ?= 'hdfs'
      options.acls['hadoop.kms.acl.GET'] ?= '*'
      options.acls['hadoop.kms.blacklist.GET'] ?= 'hdfs'
      options.acls['hadoop.kms.acl.GET_KEYS'] ?= '*'
      options.acls['hadoop.kms.blacklist.GET_KEYS'] ?= 'hdfs'
      options.acls['hadoop.kms.acl.GET_METADATA'] ?= '*'
      options.acls['hadoop.kms.blacklist.GET_METADATA'] ?= 'hdfs'
      options.acls['hadoop.kms.acl.SET_KEY_MATERIAL'] ?= '*'
      options.acls['hadoop.kms.blacklist.SET_KEY_MATERIAL'] ?= 'hdfs'
      options.acls['hadoop.kms.acl.GENERATE_EEK'] ?= '*'
      options.acls['hadoop.kms.blacklist.GENERATE_EEK'] ?= 'hdfs'
      options.acls['hadoop.kms.acl.DECRYPT_EEK'] ?= '*'
      options.acls['hadoop.kms.blacklist.DECRYPT_EEK'] ?= 'hdfs'
      options.acls['hadoop.kms.acl.GET'] ?= '*'
      options.acls['hadoop.kms.blacklist.GET'] ?= 'hdfs'
      options.acls['hadoop.kms.acl.GET'] ?= '*'
      options.acls['hadoop.kms.blacklist.GET'] ?= 'hdfs'
      options.acls['hadoop.kms.acl.GET'] ?= '*'
      options.acls['hadoop.kms.blacklist.GET'] ?= 'hdfs'
      options.acls['hadoop.kms.acl.GET'] ?= '*'
      options.acls['hadoop.kms.blacklist.GET'] ?= 'hdfs'

## Key Access Control

KMS supports access control for all non-read operations at the Key level. All
Key Access operations are classified as :

*   MANAGEMENT - createKey, deleteKey, rolloverNewVersion
*   GENERATE_EEK - generateEncryptedKey, warmUpEncryptedKeys
*   DECRYPT_EEK - decryptEncryptedKey
*   READ - getKeyVersion, getKeyVersions, getMetadata, getKeysMetadata, getCurrentKey
*   ALL - all of the above

These can be defined in the KMS etc/hadoop/kms-acls.xml as follows

For all keys for which a key access has not been explicitly configured, It is
possible to configure a default key access control for a subset of the operation
types.

It is also possible to configure a “whitelist” key ACL for a subset of the
operation types. The whitelist key ACL is a whitelist in addition to the
explicit or default per-key ACL. That is, if no per-key ACL is explicitly set,
a user will be granted access if they are present in the default per-key ACL or
the whitelist key ACL. If a per-key ACL is explicitly set, a user will be
granted access if they are present in the per-key ACL or the whitelist key ACL.

If no ACL is configured for a specific key AND no default ACL is configured AND
no root key ACL is configured for the requested operation, then access will be
DENIED.

NOTE: The default and whitelist key ACL does not support ALL operation qualifier.

      # ACL for create-key, deleteKey and rolloverNewVersion operations.
      # options.acls['key.acl.testKey1.MANAGEMENT'] ?= '*'
      # ACL for generateEncryptedKey operations.
      # options.acls['key.acl.testKey2.GENERATE_EEK'] ?= '*'
      # ACL for decryptEncryptedKey operations.
      # options.acls['key.acl.testKey3.DECRYPT_EEK'] ?= 'admink3'
      # ACL for getKeyVersion, getKeyVersions, getMetadata, getKeysMetadata,
      # getCurrentKey operations
      # options.acls['key.acl.testKey4.READ'] ?= '*'
      # ACL for ALL operations.
      # options.acls['key.acl.testKey5.ALL'] ?= '*'
      # Whitelist ACL for MANAGEMENT operations for all keys.
      # options.acls['whitelist.key.acl.MANAGEMENT'] ?= 'admin1'

## SSL

      options.ssl = merge {}, service.use.hadoop_core.options.ssl, options.ssl or {}
      # Password to the Java Keystore stored in the 'kms.keystore' file
      throw Error 'Required Options: ssl.password' unless options.ssl.password
      options.kms_site['hadoop.kms.key.provider.uri'] ?= "jceks://file@/#{options.conf_dir}/kms.keystore"
      options.kms_site['hadoop.security.keystore.java-keystore-provider.password-file'] ?= "#{options.conf_dir}/kms.keystore.password"

## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'
