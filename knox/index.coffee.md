
# Knox

The Apache Knox Gateway is a REST API gateway for interacting with Apache Hadoop
clusters. The gateway provides a single access point for all REST interactions
with Hadoop clusters.

    module.exports =
      use:
        ssl: module: 'masson/core/ssl', local: true
        iptables: module: 'masson/core/iptables', local: true
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        db_admin: module: 'ryba/commons/db_admin', local: true, auto: true, implicit: true
        test_user: module: 'ryba/commons/test_user', local: true, auto: true, implicit: true
        hdfs_nn: module: 'ryba/hadoop/hdfs_nn'
        hdfs_dn: module: 'ryba/hadoop/hdfs_dn'
        hdfs_client: module: 'ryba/hadoop/hdfs_client'
        httpfs: module: 'ryba/hadoop/httpfs'
        yarn_rm: module: 'ryba/hadoop/yarn_rm'
        yarn_nm: module: 'ryba/hadoop/yarn_nm'
        hive_server2: module: 'ryba/hive/server2'
        hive_webhcat: module: 'ryba/hive/webhcat'
        oozie_server: module: 'ryba/oozie/server'
        hbase_rest: module: 'ryba/hbase/rest'
        knox: module: 'ryba/knox'
      configure:
        'ryba/knox/configure'
        # 'ryba/ranger/plugins/knox/configure'
      commands:
        install: ->
          options = @config.ryba.knox
          @call 'ryba/knox/install', options
          @call 'ryba/knox/start', options
          @call 'ryba/knox/check', options
        check: ->
          options = @config.ryba.knox
          @call 'ryba/knox/check', options
        start: ->
          options = @config.ryba.knox
          @call 'ryba/knox/start', options
        stop: ->
          options = @config.ryba.knox
          @call 'ryba/knox/stop', options
        status:
          'ryba/knox/status'

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
