
# JanusGraph Check

    module.exports = header: 'JanusGraph Check', timeout: -1, handler: ->
      {force_check, hbase, janusgraph} = @config.ryba
      {shortname} = @config

## Wait

      @call once: true, '@rybajs/metal/hbase/master/wait'

## Check Configuration

Creates a configuration file. Always load this file in Gremlin REPL !
Check the configuration file (current.properties).

      @call header: 'Shell', timeout: -1, handler: ->
        config = {}
        config[k] = v for k, v of janusgraph.config
        config['storage.hbase.table'] = 'janusgraph-test'
        check = false
        @file.properties
          target: path.join janusgraph.home, "janusgraph-#{janusgraph.config['storage.backend']}-#{janusgraph.config['index.search.backend']}-test.properties"
          content: config
          separator: '='
        @system.execute
          cmd: mkcmd.hbase @, """
          cd #{janusgraph.home}
          #{janusgraph.install_dir}/current/bin/gremlin.sh 2>/dev/null <<< \"g = JanusGraphFactory.open('janusgraph-hbase-#{janusgraph.config['index.search.backend']}-test.properties')\" | grep '==>janusgraph'
          hbase shell 2>/dev/null <<< "grant 'ryba', 'RWC', 'janusgraph-test'"
          """
          unless_exec: unless force_check then mkcmd.test options.test_krb5_user, "hbase shell 2>/dev/null <<< \"exists 'janusgraph-test'\""
        , (err, status) ->
          check = true if status
        @system.execute
          cmd: mkcmd.test options.test_krb5_user, """
          cd #{janusgraph.home}
          cmd="TitanFactory.open('janusgraph-#{janusgraph.config['storage.backend']}-#{janusgraph.config['index.search.backend']}-test.properties')"
          #{janusgraph.install_dir}/current/bin/gremlin.sh <<< "$cmd" | grep '==>janusgraph'
          """
          if: -> check

## Dependencies

    path = require 'path'
    mkcmd = require '../lib/mkcmd'
