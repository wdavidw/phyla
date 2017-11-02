
# Configure

    module.exports = (service) ->
      service = migration.call @, service, 'ryba/ranger/admin', ['ryba', 'ranger', 'admin'], require('nikita/lib/misc').merge require('.').use,
        krb5_client: key: ['krb5_client']
        java: key: ['java']
        ssl: key: ['ssl']
        db_admin: key: ['ryba', 'db_admin']
        hadoop_core: key: ['ryba']
        hdfs_client: key: ['ryba', 'hdfs_client']
        ranger_admin: key: ['ryba', 'ranger', 'admin']
        openldap_server: key: ['openldap_server']
      @config.ryba.ranger ?= {}
      options = @config.ryba.ranger.usersync ?= {}

## Identities

By default, merge group and user from the Ranger admin configuration.

      options.group = merge {}, service.use.ranger_admin[0].options.group, options.group
      options.user = merge {}, service.use.ranger_admin[0].options.user, options.user

## Environment

      options.conf_dir ?= '/etc/ranger/usersync/conf'
      options.log_dir ?= '/var/log/ranger'
      options.pid_dir ?= '/var/run/ranger'
      options.site ?= {}
      options.install ?= {}
      options.site ?= {}

Setup Scripts are used to install ranger-usersync tool. Setup scripts read properties 
from two files:
* First is `/usr/hdp/current/ranger-usersync/install.properties` file (documented).
* Second is `/usr/hdp/current/ranger-usersync/conf.dist/ranger-usersync-default.xml`.
Setup process creates files in `/etc/ranger/usersync/conf` dir and outputs final
 properties to `ranger-ugsync-site.xml` file.

## Policy Admin Tool

      options.install['POLICY_MGR_URL'] ?= service.use.ranger_admin[0].options.install['policymgr_external_url']


## User Group Source Information
Specifies where the user/group information is extracted to be put into Ranger 
database:
 * Unix - get user information from /etc/passwd file and gets group information.
 from /etc/group file
 * LDAP - gets user information from LDAP service.
 In case LDAP is configured, Ryba looks first in the global `config.ryba.ranger['ldap_provider']` conf object 
 for needed properties (e.g. ldap url, bind dn...), and if not set try to discover
 it from `masson/core/openldap` module (if installed).

      options.install['SYNC_SOURCE'] ?= 'ldap'
      options.install['SYNC_INTERVAL'] ?= '1' # in minutes
      switch options.install['SYNC_SOURCE']
        when 'unix'
          options.install['MIN_UNIX_USER_ID_TO_SYNC'] ?= '300'
        when 'ldap'
          if  !options.install['SYNC_LDAP_URL']?
            throw Error 'No openldap server configured' unless service.use.openldap_server?
            options.install['SYNC_LDAP_URL'] ?= "#{service.use.openldap_server.optionsuri}"
            options.install['SYNC_LDAP_BIND_DN'] ?= "#{service.use.openldap_server.optionsroot_dn}"
            options.install['SYNC_LDAP_BIND_PASSWORD'] ?= "#{service.use.openldap_server.optionsroot_password}"
            options.install['CRED_KEYSTORE_FILENAME'] ?= "#{options.conf_dir}/rangerusersync.jceks"
            options.install['SYNC_LDAP_USER_SEARCH_BASE'] ?= "ou=users,#{service.use.openldap_server.optionssuffix}"
            options.install['SYNC_LDAP_USER_SEARCH_SCOPE'] ?= "ou=groups,#{service.use.openldap_server.optionssuffix}"
            options.install['SYNC_LDAP_USER_OBJECT_CLASS'] ?= 'posixAccount'
            options.install['SYNC_LDAP_USER_SEARCH_FILTER'] ?= 'cn={0}'
            options.install['SYNC_LDAP_USER_NAME_ATTRIBUTE'] ?= 'cn'
            options.install['SYNC_GROUP_OBJECT_CLASS'] ?= 'posixGroup'
            options.install['SYNC_LDAP_USER_GROUP_NAME_ATTRIBUTE'] ?= 'cn'
            options.install['SYNC_LDAP_USERNAME_CASE_CONVERSION'] ?= 'none'
            options.install['SYNC_LDAP_GROUPNAME_CASE_CONVERSION'] ?= 'none'
            options.install['SYNC_GROUP_SEARCH_ENABLED'] ?= 'false'
            options.site['options.ldap.searchBase'] ?= "#{service.use.openldap_server.optionssuffix}"
          options.install['MIN_UNIX_USER_ID_TO_SYNC'] ?= '500'
        else return throw new Error 'sync source is not legal'

## User Synchronization Process

      options.install['unix_user'] ?= options.user.name
      options.install['unix_group'] ?= options.group.name
      options.install['hadoop_conf'] ?= '/etc/hadoop/conf'
      options.install['logdir'] ?= '/var/log/ranger/usersync'

Nonetheless some of the properties are hard coded to `/usr/hdp/current/ranger-usersync/setup.py`
file. Administrators can override following properties.

      setup = options.setup ?= {}
      setup['pidFolderName'] ?= options.pid_dir
      setup['logFolderName'] ?= options.log_dir


SSl properties are not documented, they are extracted from setup.py scripts.

## SSL

      options.default ?= {}
      # options.default['options.ssl'] ?= 'true'
      options.default['options.keystore.file'] ?= "#{options.conf_dir}/keystore"
      options.default['options.keystore.password'] ?= 'ranger123'
      options.default['options.truststore.file'] ?= "#{options.conf_dir}/truststore"
      options.default['options.truststore.password'] ?= 'ranger123'


## Env

      options.heap_size ?= '256m'
      options.opts ?= {}
      options.opts['javax.net.ssl.trustStore'] ?= '/etc/hadoop/conf/truststore'
      options.opts['javax.net.ssl.trustStorePassword'] ?= 'ryba123'


## Dependencies

    {merge} = require 'nikita/lib/misc'
    migration = require 'masson/lib/migration'
    path = require 'path'
    {merge} = require 'nikita/lib/misc'

[ambari-conf-example]:(https://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.0/bk_Ranger_Install_Guide/content/ranger-usersync_settings.html)
[ranger-usersync]:(http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.4.0/bk_installing_manually_book/content/install_and_start_user_sync_ranger.html)
