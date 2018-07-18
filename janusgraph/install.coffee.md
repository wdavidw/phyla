
# JanusGraph Install

Install the JanusGraph archive. It contains scripts for:
*   the Gremlin REPL
*   the Rexster Server

Note: the archive contains the rexster server but it is not configured here,
please see ryba/rexster

    module.exports = header: 'JanusGraph Install', handler: ->
      {janusgraph, hbase} = @config.ryba

      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## Install

Download and extract a ZIP Archive

      @call header: 'Packages', ->
        archive_name = path.basename janusgraph.source
        unzip_dir = path.join janusgraph.install_dir, path.basename archive_name, path.extname archive_name
        archive_path = path.join janusgraph.install_dir, archive_name
        @system.mkdir
          target: janusgraph.install_dir
        @file.download
          source: janusgraph.source
          target: archive_path
        @system.remove
          target: unzip_dir
          if: -> @status -1
        @tools.extract
          source: archive_path,
          target: janusgraph.install_dir
        @system.remove
          target: janusgraph.home
          if: -> @status -1
        @system.link
          source: unzip_dir
          target: janusgraph.home
          if: -> @status -2

## Env

Modify envvars in the gremlin scripts.

      @call header: 'Gremlin Env', ->
        write = [
          match: /^JAVA_OPTIONS="\$JAVA_OPTIONS -Djava.security.auth.login.config=.*/m
          replace: "JAVA_OPTIONS=\"$JAVA_OPTIONS -Djava.security.auth.login.config=#{path.join janusgraph.home, 'janusgraph.jaas'}\" # RYBA CONF, DON'T OVERWRITE"
          place_before: /^exec \$JAVA \$JAVA_OPTIONS \$MAIN_CLASS.*/m
        ,
          match: /^JAVA_OPTIONS="\$JAVA_OPTIONS -Djava.library.path=.*/m
          replace: "JAVA_OPTIONS=\"$JAVA_OPTIONS -Djava.library.path=${HADOOP_HOME}/lib/native\" # RYBA CONF, DON'T OVERWRITE"
          place_before: /^exec \$JAVA \$JAVA_OPTIONS \$MAIN_CLASS.*/m
        ,
          match: /^(.*)# RYBA SET HADOOP-ENV, DON'T OVERWRITE/m
          replace: "HADOOP_HOME=/usr/hdp/current/hadoop-client # RYBA SET HADOOP-ENV, DON'T OVERWRITE"
          append: /^set -u.*/m
        ]
        if janusgraph.config['storage.backend'] is 'hbase' then write.unshift
          match: /^.*# RYBA CONF hbase-env, DON'T OVERWRITE/m
          replace: "CP=\"$CP:#{@config.ryba.hbase.conf_dir}:/etc/hadoop/conf\" # RYBA CONF hbase-env, DON'T OVERWRITE"
          place_before: /^export CLASSPATH=.*/m
        @file
          target: path.join janusgraph.home, 'bin/gremlin.sh'
          write: write
          mode: 0o755

## Kerberos

Secure the Zookeeper connection with JAAS

      @file.jaas
        header: 'Kerberos JAAS'
        target: path.join janusgraph.home, 'janusgraph.jaas'
        content: Client:
          useTicketCache: 'true'
        mode: 0o644

## Configure

Creates a configuration file. Always load this file in Gremlin REPL !

      @call header: 'Gremlin Properties', ->
        storage = janusgraph.config['storage.backend']
        index = janusgraph.config['index.search.backend']
        @file.properties
          target: path.join janusgraph.home, "janusgraph.#{storage}-#{index}.properties"
          content: janusgraph.config
          backup: true
          eof: true

# ## Configure Test

# Creates a configuration file. Always load this file in Gremlin REPL !

#     module.exports.push header: 'Gremlin Test Properties', ->
#       {janusgraph. = @config.ryba
#       storage = janusgraph.config['storage.backend']
#       config = {}
#       config[k] = v for k, v of janusgraph.config
#       config['storage.hbase.table'] = 'janusgraph.test'
#       @file.properties
#         target: path.join janusgraph.home, "janusgraph.hbase-#{janusgraph.config['index.search.backend']}-test.properties"
#         content: config
#         merge: true

## HBase Configuration

Namespace is still not working in version 1.0

      # @call
      #   header: 'Create HBase Namespace'
      #   if: -> @config.ryba.janusgraph.config['storage.backend'] is 'hbase'
      # , (options) ->
      #   # @log "Titan: HBase namespace not yet ready"
      #   @system.execute
      #     cmd: mkcmd.hbase @, """
      #     if hbase shell -n 2>/dev/null <<< "list_namespace 'janusgraph." | grep '1 row(s)'; then exit 3; fi
      #     hbase shell -n 2>/dev/null <<< "create_namespace 'janusgraph."
      #     """
      #     code_skipped: 3

      @call
        header: 'Create HBase table'
        if: -> @config.ryba.janusgraph.config['storage.backend'] is 'hbase'
      , ->
        table = janusgraph.config['storage.hbase.table']
        @system.execute
          cmd: mkcmd.hbase @, """
          if hbase shell -n 2>/dev/null <<< "exists '#{table}'" | grep 'Table #{table} does exist'; then exit 3; fi
          cd #{janusgraph.home}
          bin/gremlin.sh 2>/dev/null <<< \"g = JanusGraphFactory.open('janusgraph.hbase-#{janusgraph.config['index.search.backend']}.properties')\" | grep '==>janusgraph.raph'
          """
          code_skipped: 3

## Dependencies

    path = require 'path'
    mkcmd = require '../lib/mkcmd'
