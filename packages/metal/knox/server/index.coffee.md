
# Knox

The Apache Knox Gateway is a REST API gateway for interacting with Apache Hadoop
clusters. The gateway provides a single access point for all REST interactions
with Hadoop clusters.

    module.exports =
      deps:
        ssl: module: 'masson/core/ssl', local: true
        sssd: module: 'masson/core/sssd', local: true
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        db_admin: module: '@rybajs/metal/commons/db_admin', local: true, auto: true, implicit: true
        test_user: module: '@rybajs/metal/commons/test_user', local: true, auto: true, implicit: true
        hdfs_nn: module: '@rybajs/metal/hadoop/hdfs_nn'
        hdfs_dn: module: '@rybajs/metal/hadoop/hdfs_dn'
        hdfs_client: module: '@rybajs/metal/hadoop/hdfs_client'
        httpfs: module: '@rybajs/metal/hadoop/httpfs'
        yarn_rm: module: '@rybajs/metal/hadoop/yarn_rm'
        yarn_nm: module: '@rybajs/metal/hadoop/yarn_nm'
        yarn_ts: module: '@rybajs/metal/hadoop/yarn_ts'
        mapred_jhs: module: '@rybajs/metal/hadoop/mapred_jhs'
        hive_server2: module: '@rybajs/metal/hive/server2'
        hive_webhcat: module: '@rybajs/metal/hive/webhcat'
        oozie_server: module: '@rybajs/metal/oozie/server'
        hbase_rest: module: '@rybajs/metal/hbase/rest'
        knox_server: module: '@rybajs/metal/knox/server'
        ranger_admin: module: '@rybajs/metal/ranger/admin', single: true
        log4j: module: '@rybajs/metal/log4j', local: true
      configure:
        '@rybajs/metal/knox/server/configure'
      commands:
        install: [
          '@rybajs/metal/knox/server/install'
          '@rybajs/metal/knox/server/start'
          '@rybajs/metal/knox/server/check'
        ]
        check:
          '@rybajs/metal/knox/server/check'
        start:
          '@rybajs/metal/knox/server/start'
        stop:
          '@rybajs/metal/knox/server/stop'
        status:
          '@rybajs/metal/knox/server/status'

# Knox Installation and configuration

## Configure LDAP

There is two ways to configure Knox for LDAP authorization.
Final user give a MD5 digest login:password to Knox. Knox checks this user in 
an LDAP.
There is two different case
1. the digest is sufficient to contact LDAP
2. LDAP is readable through a specific user

### LDAP is readable by any user

To check if LDAP is readable by any user please execute on Knox client
```bash
ldapsearch -h $ldap_host -p $ldap_port -D "$user_dn" -w password -b "$user_dn" "objectclass=*"
```

If the result is OK then in knox topology shiro provider please set
main.ldapRealm.userDnTemplate.

This value is used to construct user_dn with the user provided by the MD5-digest.

for example :

if main.ldapRealm.userDnTemplate = cn={0},ou=users,dc=ryba then this request:

```
curl -iku hdfs:test123 https://$knox_host:$knox_port/gateway/$cluster/$service
```
will result in this equivalent ldap check (it is not what Knox exactly do, but is equivalent)

```
ldapsearch -h $ldap_host -p $ldap_port -D "cn=hdfs,ou=users,dc=ryba" -w test123 -b "cn=hdfs,ou=users,dc=ryba" "objectclass=*"
```

### LDAP search

If LDAP is not readable, or user_dn cannot be assessed with username 
(users are located in more than one branch in the LDAP tree),
you need to use the knox ldap search functionality

Please specify:
```xml
<param>
    <name>main.ldapRealm.userObjectClass</name>
    <value>person</value>
</param>
<param>
    <!-- filter from this base -->
    <name>main.ldapRealm.searchBase</name>
    <value>ou=users,dc=ryba</value>
</param>
<param>
    <!-- filter: uid={0} -->
    <name>ldapRealm.userSearchAttributeName</name>
    <value>uid</value>
</param>
<param>
    <!-- granted ldap user if needed -->
    <name>main.ldapRealm.contextFactory.systemUsername</name>
    <value>cn=Manager,dc=ryba</value>
</param>
<param>
    <name>main.ldapRealm.contextFactory.systemPassword</name>
    <value>test</value>
</param>
```

which is equivalent to 
```bash
ldapsearch -h $ldap_host -p $ldap_port -D "$systemUsername" -w $systemPassword -b "$searchBase" -Z "$attr={0}" "objectclass=$userObjectClass"
```

## HDFS HA

Hortonworks documentation is uncorrect (last checked documentation: hdp-2.3.2).
Hence please refer to the [official Apache documentation][doc]

[doc]: http://knox.apache.org/books/knox-0-6-0/user-guide.html
