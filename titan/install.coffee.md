
# Titan Install

Install titan archive. It contains scripts for:
*   the Gremlin REPL
*   the Rexster Server

Note: the archive contains the rexster server but it is not configured here,
please see ryba/rexster

    module.exports = header: 'Titan Install', handler: ->
      {titan, hbase} = @config.ryba

      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## Install

Download and extract a ZIP Archive

      @call header: 'Packages', ->
        archive_name = path.basename titan.source
        unzip_dir = path.join titan.install_dir, path.basename archive_name, path.extname archive_name
        archive_path = path.join titan.install_dir, archive_name
        @system.mkdir
          target: titan.install_dir
        @file.download
          source: titan.source
          target: archive_path
        @system.remove
          target: unzip_dir
          if: -> @status -1
        @tools.extract
          source: archive_path,
          target: titan.install_dir
        @system.remove
          target: titan.home
          if: -> @status -1
        @system.link
          source: unzip_dir
          target: titan.home
          if: -> @status -2

## Env

Modify envvars in the gremlin scripts.

      @call header: 'Gremlin Env', ->
        write = [
          match: /^(.*)JAVA_OPTIONS="-Dlog4j.configuration=[^f].*/m
          replace: "    JAVA_OPTIONS=\"-Dlog4j.configuration=file:#{path.join titan.home, 'conf', 'log4j-gremlin.properties'}\" # RYBA CONF, DON'T OVERWRITE"
        ,
          match: /^(.*)-Djava.security.auth.login.config=.*/m
          replace: "    JAVA_OPTIONS=\"$JAVA_OPTIONS -Djava.security.auth.login.config=#{path.join titan.home, 'titan.jaas'}\" # RYBA CONF, DON'T OVERWRITE"
          append: /^(.*)-Dgremlin.mr.log4j.level=.*/m
        ,
          match: /^(.*)-Djava.library.path.*/m
          replace: "    JAVA_OPTIONS=\"$JAVA_OPTIONS -Djava.library.path=${HADOOP_HOME}/lib/native\" # RYBA CONF, DON'T OVERWRITE"
          append: /^(.*)-Dgremlin.mr.log4j.level=.*/m
        ,
          match: /^(.*)# RYBA SET HADOOP-ENV, DON'T OVERWRITE/m
          replace: "HADOOP_HOME=/usr/hdp/current/hadoop-client # RYBA SET HADOOP-ENV, DON'T OVERWRITE"
          place_before: /^CP=`abs_path`.*/m
        ]
        if titan.config['storage.backend'] is 'hbase' then write.unshift
          match: /^.*# RYBA CONF hbase-env, DON'T OVERWRITE/m
          replace: "CP=\"$CP:#{@config.ryba.hbase.conf_dir}\" # RYBA CONF hbase-env, DON'T OVERWRITE"
          append: /^CP=`abs_path`.*/m
        @file
          target: path.join titan.home, 'bin/gremlin.sh'
          write: write

## Kerberos

Secure the Zookeeper connection with JAAS

      @file.jaas
        header: 'Kerberos JAAS'
        target: path.join titan.home, 'titan.jaas'
        content: Client:
          useTicketCache: 'true'
        mode: 0o644

## Configure

Creates a configuration file. Always load this file in Gremlin REPL !

      @call header: 'Gremlin Properties', ->
        storage = titan.config['storage.backend']
        index = titan.config['index.search.backend']
        @file.properties
          target: path.join titan.home, "titan-#{storage}-#{index}.properties"
          content: titan.config
          backup: true
          eof: true

# ## Configure Test

# Creates a configuration file. Always load this file in Gremlin REPL !

#     module.exports.push header: 'Gremlin Test Properties', ->
#       {titan} = @config.ryba
#       storage = titan.config['storage.backend']
#       config = {}
#       config[k] = v for k, v of titan.config
#       config['storage.hbase.table'] = 'titan-test'
#       @file.properties
#         target: path.join titan.home, "titan-hbase-#{titan.config['index.search.backend']}-test.properties"
#         content: config
#         merge: true

## HBase Configuration

Namespace is still not working in version 1.0

      # @call
      #   header: 'Create HBase Namespace'
      #   if: -> @config.ryba.titan.config['storage.backend'] is 'hbase'
      # , (options) ->
      #   # @log "Titan: HBase namespace not yet ready"
      #   @system.execute
      #     cmd: mkcmd.hbase @, """
      #     if hbase shell -n 2>/dev/null <<< "list_namespace 'titan'" | grep '1 row(s)'; then exit 3; fi
      #     hbase shell -n 2>/dev/null <<< "create_namespace 'titan'"
      #     """
      #     code_skipped: 3

      @call
        header: 'Create HBase table'
        if: -> @config.ryba.titan.config['storage.backend'] is 'hbase'
      , ->
        table = titan.config['storage.hbase.table']
        @system.execute
          cmd: mkcmd.hbase @, """
          if hbase shell -n 2>/dev/null <<< "exists '#{table}'" | grep 'Table #{table} does exist'; then exit 3; fi
          cd #{titan.home}
          #{titan.install_dir}/current/bin/gremlin.sh 2>/dev/null <<< \"g = TitanFactory.open('titan-hbase-#{titan.config['index.search.backend']}.properties')\" | grep '==>titangraph'
          """
          code_skipped: 3

## Dependencies

    path = require 'path'
    mkcmd = require '../lib/mkcmd'
