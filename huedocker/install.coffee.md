
# Hue Install

Install  dockerized hue 3.8 container. The container can be build by ./bin/prepare
script or directly downloaded (from local computer only for now,
no images available on dockerhub).

Run `ryba prepare` to create the Docker container.

    module.exports = header: 'Hue Docker Install', handler: (options) ->

## Register

      @registry.register 'hconfigure', 'ryba/lib/hconfigure'

## Wait
Wait only needed service for starting.

      @call 'ryba/commons/db_admin/wait', once: true, options.wait_db_admin

## Identities

By default, the "hue" package create the following entries:

```bash
cat /etc/passwd | grep hue
hue:x:494:494:Hue:/var/lib/hue:/sbin/nologin
cat /etc/group | grep hue
hue:x:494:
```

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## IPTables

| Service    | Port  | Proto | Parameter          |
|------------|-------|-------|--------------------|
| Hue Web UI | 8888  | http  | desktop.http_port  |

IPTables rules are only inserted if the parameter "iptables.action" is set to
"start" (default value).

      @tools.iptables
        header: 'IPTables'
        rules: [
          { chain: 'INPUT', jump: 'ACCEPT', dport: options.ini.desktop.http_port, protocol: 'tcp', state: 'NEW', comment: "Hue Web UI" }
        ]
        if: options.iptables

## Layout log Hue

      @call header: 'Layout', ->
        @system.mkdir
          target: options.log_dir
          uid: options.user.name
          gid: options.group.name
          mode: 0o755
          parent: true
        @system.mkdir
          target: '/tmp/hue_docker'
          uid: options.user.name
          gid: options.group.name
          mode: 0o755
        @system.mkdir
          target: "#{options.conf_dir}"
          uid: options.user.name
          gid: options.group.name
          mode: 0o755

## Configure

Configure the "/etc/hue/conf" file following the [HortonWorks](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.0.8.0/bk_installing_manually_book/content/rpm-chap-hue-5-2.html)
recommandations. Merge the configuration object from "pseudo-distributed.ini" with the properties of the target file.

      @file.ini
        target: "#{options.conf_dir}/hue_docker.ini"
        content: options.ini
        backup: true
        parse: misc.ini.parse_multi_brackets
        stringify: misc.ini.stringify_multi_brackets
        separator: '='
        comment: '#'
        uid: options.user.name
        gid: options.group.name
        mode: 0o0750

## DB

Setup the database hosting the Hue data. Currently two database providers are
implemented but Hue supports MySQL, PostgreSQL, and Oracle. Note, sqlite is
the default database while mysql is the recommanded choice.

      @call header: 'Hue Docker DB', ->
        @db.user options.db, database: null,
          header: 'User'
          if: options.db.engine in ['mariadb', 'postgresql', 'mysql']
        @db.database options.db,
          header: 'Database'
          user: options.db.username
          if: options.db.engine in ['mariadb', 'postgresql', 'mysql']
        @db.schema options.db,
          header: 'Schema'
          if: options.db.engine is 'postgresql'
          schema: options.db.schema or options.db.database
          database: options.db.database
          owner: options.db.username
        # switch options.ini.desktop.database.engine
        #   when 'mysql'
        #     {engine, host, user, password, name} = options.ini.desktop.database
        #     escape = (text) -> text.replace(/[\\"]/g, "\\$&")
        #     properties =
        #       'engine': engine
        #       'host': host
        #       'admin_username': db_admin[engine]['admin_username']
        #       'admin_password': db_admin[engine]['admin_password']
        #       'username': user
        #       'password': password
        #     @db.user properties,
        #       header: 'User'
        #     @db.database properties, database: name,
        #       header: 'Database'
        #     @system.execute
        #       cmd: db.cmd properties, """
        #         grant all privileges on #{name}.* to '#{user}'@'localhost' identified by '#{password}';
        #         grant all privileges on #{name}.* to '#{user}'@'%' identified by '#{password}';
        #         flush privileges;
        #       """
        #       unless_exec: db.cmd properties, "select * from #{name}.axes_accessattempt limit 1;"
        #   else throw Error 'Hue database engine not supported'

## Kerberos

The principal for the Hue service is created and named after "hue/{host}@{realm}". inside
the "/etc/hue/conf/options.ini" configuration file, all the composants myst be tagged with
the "security_enabled" property set to "true".

      @krb5.addprinc options.krb5.admin,
        header: 'Kerberos'
        principal: options.ini.desktop.kerberos.hue_principal
        randkey: true
        keytab: options.ini.desktop.kerberos.hue_keytab
        uid: options.user.name
        gid: options.group.name

## SSL Server

Upload and register the SSL certificate and private key respectively defined
by the "options.ssl.cert" and "hdp.hue_docker.ssl.private_key"
configuration properties. It follows the [official Hue Web Server
Configuration][web]. The "hue" service is restarted if there was any
changes.

Write truststore into /etc/huedocker/conf folder for hue to be able to connect as a
client over ssl. Then the REQUESTS_CA_BUNDLE environment variable is set to the
path  during docker run.

      @call header: 'SSL Server', ->
        return unless options.ssl.enabled
        @file.download
          source: options.ssl.cert.source
          target: options.ini['desktop']['ssl_certificate']
          local: options.ssl.cert.local
          uid: options.user.name
          gid: options.group.name
        @file.download
          source: options.ssl.key.source
          target: options.ini['desktop']['ssl_private_key']
          local: options.ssl.key.local
          uid: options.user.name
          gid: options.group.name
        @file.download
          target: options.ca_bundle
          source: options.ssl.cacert.source
          local: options.ssl.cacert.local
          backup: true

## Install Hue container

Install Hue server docker container.
It uses local checksum if provided to upload or not.

      @call header: 'Upload Container', retry:3,  ->
        tmp = options.image_dir
        md5 = options.md5 ?= true
        @docker.checksum
          docker: options.swarm_conf
          image: options.image
          tag: options.version
        @docker.pull
          header: 'Pull container'
          unless: -> @status(-1)
          tag: options.image
          version: options.version
          code_skipped: 1
        @file.download
          unless: -> @status(-1) or @status(-2)
          source: "#{options.prod.directory}/#{options.prod.tar}"
          target: "#{tmp}/#{options.prod.tar}"
          binary: true
          md5: md5
        @docker.load
          header: 'Load container to docker'
          unless: -> @status(-3)
          if_exists: "#{tmp}/#{options.prod.tar}"
          source:"#{tmp}/#{options.prod.tar}"
          docker: options.swarm_conf

## Run Hue Server Container

Runs the hue docker container after configuration and installation
```
docker run --name hue_server --net host -d -v /etc/hadoop/conf:/etc/hadoop/conf
-v /etc/hadoop-httpfs/conf:/etc/hadoop-httpfs/conf -v /etc/hive/conf:/etc/hive/conf
-v /etc/hue/conf:/etc/hue/conf -v /var/log/hue:/var/log/hue -v /etc/krb5.conf:/etc/krb5.conf
-v /etc/security/keytabs:/etc/security/keytabs -v /etc/usr/hdp:/usr/hdp
-v /etc/hue/conf/options.ini:/var/lib/hue/desktop/conf/pseudo-distributed.ini
-e REQUESTS_CA_BUNDLE=/etc/hue/conf/trust.pem -e KRB5CCNAME=:/tmp/krb5cc_2410
ryba/hue:3.9

```

      @docker.service
        header: 'Run'
        force: -> @status -1
        image: "#{options.image}:#{options.version}"
        volume: [
          "#{options.conf_dir}/hue_docker.ini:/var/lib/hue/desktop/conf/pseudo-distributed.ini"
          "#{options.ini['hadoop']['hdfs_clusters']['default']['hadoop_conf_dir']}:#{options.ini['hadoop']['hdfs_clusters']['default']['hadoop_conf_dir']}"
          "#{options.ini['hbase']['hbase_conf_dir']}:#{options.ini['hbase']['hbase_conf_dir']}"
          "#{options.ini['beeswax']['hive_conf_dir']}:#{ options.ini['beeswax']['hive_conf_dir']}"
          "#{options.conf_dir}:#{options.conf_dir}"
          "#{options.log_dir}:/var/lib/hue/logs"
          '/etc/krb5.conf:/etc/krb5.conf'
          '/etc/security/keytabs:/etc/security/keytabs'
          '/etc/usr/hdp:/usr/hdp'
          '/tmp/hue_docker:/tmp'
        ]
        # Fix SSL Communication between hue as client and hadoop components
        # by setting the ca bundle path as global env variable
        env: [
          "REQUESTS_CA_BUNDLE=#{options.ca_bundle}"
          "KRB5CCNAME=FILE:/tmp/krb5cc_#{options.user.uid}"
          "DESKTOP_LOG_DIR=/var/lib/hue/logs"
        ]
        net: 'host'
        service: true
        name: options.container

## Startup Script

Write startup script to /etc/init.d/service-hue-docker

      @service.init
        if_os: name: ['redhat','centos'], version: '6'
        source: "#{__dirname}/resources/hue-server-docker.j2"
        local: true
        target: "/etc/init.d/#{options.service}"
        context: options
        mode: 0o755
      @call
        if_os: name: ['redhat','centos'], version: '7'
      , ->
        @service.init
          header: 'Systemd Script'
          target: "/usr/lib/systemd/system/#{options.service}.service"
          source: "#{__dirname}/resources/hue-server-docker-systemd.j2"
          local: true
          context: options
          mode: 0o0640
        @system.tmpfs
          header: 'Run dir'
          mount: options.pid_file
          uid: options.user.name
          gid: options.group.name
          perm: '0750'

## Dependencies

    misc = require 'nikita/lib/misc'
    fs = require 'fs'
    db = require 'nikita/lib/misc/db'

## Resources:

*   [Official Hue website](http://gethue_docker.com)
*   [Hortonworks instructions](http://docs.hortonworks.com/HDPDocuments/HDP2/HDP-2.3.2/bk_installing_manually_book/content/configure_hdp_hue_docker.html)
*   [Cloudera instructions](https://github.com/cloudera/hue#development-prerequisites)

## Notes

Compilation requirements: ant asciidoc cyrus-sasl-devel cyrus-sasl-gssapi gcc gcc-c++ krb5-devel libtidy libxml2-devel libxslt-devel mvn mysql mysql-devel openldap-devel python-devel python-simplejson sqlite-devel

[web]: http://gethue_docker.com/docs-3.5.0/manual.html#_web_server_configuration
