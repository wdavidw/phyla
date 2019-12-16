
# Ranger Usersync Process

    module.exports = header: 'Ranger UserSync Install', handler: ({options}) ->

## Registry

      @registry.register 'hdp_select', '@rybajs/metal/lib/hdp_select'

## Identities

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Package

Install the Ranger user Sync package and set it to the latest version. Note, we
select the "kafka-broker" hdp directory. There is no "kafka-consumer"
directories.

      @call header: 'Packages', ->
        hdp_current_version = null
        @call (_, callback) =>
          @system.execute
            cmd:  "hdp-select versions | tail -1 | tr '.' '_' | tr '-' '_'"
          , (err, data) =>
            return callback err if err
            hdp_current_version = data.stdout.trim()
            return callback null, data.status
        @call ->
          @service
            name: "ranger_#{hdp_current_version}-usersync"
        @hdp_select
          name: 'ranger-usersync'

      @call header: 'Layout', ->
        @system.mkdir
          target: options.conf_dir
        @system.mkdir
          target: options.log_dir
        @system.tmpfs
          if_os: name: ['redhat','centos'], version: '7'
          mount: options.pid_dir
          uid: options.user.name
          gid: options.group.name
          perm: '0750'
        @system.mkdir
          target: options.pid_dir


# ## IPTables
#
# | Service              | Port  | Proto       | Parameter          |
# |----------------------|-------|-------------|--------------------|
# | Ranger policymanager | 6080  | http        | port               |
# | Ranger policymanager | 6082  | https       | port               |
#
# IPTables rules are only inserted if the parameter "iptables.action" is set to
# "start" (default value).
#
#     module.exports.push
#       header: 'Ranger Admin IPTables',
#      , ->
#       {ranger} = @config.ryba
#       return unless @config.iptables.action is 'start'
#       @tools.iptables
#         rules: [
#           { chain: 'INPUT', jump: 'ACCEPT', dport: ranger.admin.site['ranger.service.http.port'], protocol: 'tcp', state: 'NEW', comment: "Ranger Admin HTTP WEBUI" }
#           { chain: 'INPUT', jump: 'ACCEPT', dport: ranger.admin.site['ranger.service.https.port'], protocol: 'tcp', state: 'NEW', comment: "Ranger Admin HTTPS WEBUI" }
#         ]

# ## Ranger ranger-usersync Driver
#
#     module.exports.push header: 'Ranger Admin Driver', ->
#       {ranger} = @config.ryba
#       @system.link
#         source: '/usr/share/java/mysql-connector-java.jar'
#         target: ranger.admin.install['SQL_CONNECTOR_JAR']


## Setup Scripts

Update the file "install.properties" with the properties defined by the
"ryba.options.install" configuration.

      @file.render
        header: 'Configure Install Scripts'
        target: "/usr/hdp/current/ranger-usersync/install.properties"
        source: "#{__dirname}/../resources/usersync-install-properties.j2"
        local: true
        context: options
        write: for k, v of options.install
          match: RegExp "^#{quote k}=.*$", 'mg'
          replace: "#{k}=#{v}"
          append: true
        eof: true
        backup: true

      @file
        header: 'Configure Setup Scripts'
        target: '/usr/hdp/current/ranger-usersync/setup.py'
        write : for k, v of options.setup
          match: RegExp "^#{quote k} =.*$", 'mg'
          replace: "#{k} = '#{v}'"
          append: true
        mode: 0o750
        eof: true
        backup: true

      @system.execute
        header: 'Execute Setup Scripts'
        cmd: """
        cd /usr/hdp/current/ranger-usersync/
        ./setup.sh
        """

      # the setup scripts already render an init.d script but it does not respect 
      # the convention exit code 3 when service is stopped on the status code
      @service.init
        target: '/etc/init.d/ranger-usersync'
        source: "#{__dirname}/../resources/ranger-usersync.j2"
        local: true
        mode: 0o0755
        context: options

      writes = [
        match: RegExp "JAVA_OPTS=.*", 'm'
        replace: "JAVA_OPTS=\"${JAVA_OPTS} -Xmx#{options.heap_size} -Xms#{options.heap_size} \""
        append: true
      ]
      for k,v of options.opts
        writes.push
          match: RegExp "^JAVA_OPTS=.*#{k}", 'm'
          replace: "JAVA_OPTS=\"${JAVA_OPTS} -D#{k}=#{v}\" # RYBA, DONT OVERWRITE '@rybajs/metal/ranger/usersync'"
          append: true
      @file
        header: 'Usersync Env'
        target: '/etc/ranger/usersync/conf/ranger-usersync-env-1.sh'
        write: writes

      @file.types.hfile
        header: 'Usersync site'
        target: "/etc/ranger/usersync/conf/ranger-ugsync-site.xml"
        properties: options.site
        merge: true
        backup: true
      #
      # @java.keystore_add
      #   keystore: options.site['options.truststore.file']
      #   storepass: 'ryba123'
      #   caname: "hadoop_root_ca"
      #   cacert: "#{ssl.cacert}"
      #   local: true
      # @java.keystore_add
      #   keystore: ranger.admin.site['ranger.https.attrib.keystore.file']
      #   storepass: ranger.admin.site['ranger.service.https.attrib.keystore.pass']
      #   caname: "hadoop_root_ca"
      #   cacert: "#{ssl.cacert}"
      #   key: "#{ssl.key}"
      #   cert: "#{ssl.cert}"
      #   keypass: 'ryba123'
      #   name: ranger.admin.site['ranger.service.https.attrib.keystore.keyalias']
      #   local: true
      # @java.keystore_add
      #   keystore: ranger.admin.site['ranger.https.attrib.keystore.file']
      #   storepass: ranger.admin.site['ranger.service.https.attrib.keystore.pass']
      #   caname: "hadoop_root_ca"
      #   cacert: "#{ssl.cacert}"
      #   local: true

## Dependencies

    glob = require 'glob'
    path = require 'path'
    quote = require 'regexp-quote'
