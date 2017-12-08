
# Titan Check

    module.exports = header: 'Titan Check', handler: ->
      {force_check, hbase, titan} = @config.ryba
      {shortname} = @config

## Wait

      @call once: true, 'ryba/hbase/master/wait'

## Check Configuration

Creates a configuration file. Always load this file in Gremlin REPL !
Check the configuration file (current.properties).

      @call header: 'Check Shell', ->
        config = {}
        config[k] = v for k, v of titan.config
        config['storage.hbase.table'] = 'titan-test'
        check = false
        @file.properties
          target: path.join titan.home, "titan-#{titan.config['storage.backend']}-#{titan.config['index.search.backend']}-test.properties"
          content: config
          separator: '='
        @system.execute
          cmd: mkcmd.hbase @, """
          cd #{titan.home}
          #{titan.install_dir}/current/bin/gremlin.sh 2>/dev/null <<< \"g = TitanFactory.open('titan-hbase-#{titan.config['index.search.backend']}-test.properties')\" | grep '==>titangraph'
          hbase shell 2>/dev/null <<< "grant 'ryba', 'RWC', 'titan-test'"
          """
          unless_exec: unless force_check then mkcmd.test @, "hbase shell 2>/dev/null <<< \"exists 'titan-test'\""
        , (err, status) ->
          check = true if status
        @system.execute
          cmd: mkcmd.test @, """
          cd #{titan.home}
          cmd="TitanFactory.open('titan-#{titan.config['storage.backend']}-#{titan.config['index.search.backend']}-test.properties')"
          #{titan.install_dir}/current/bin/gremlin.sh <<< "$cmd" | grep '==>titangraph'
          """
          if: -> check

## Dependencies

    path = require 'path'
    mkcmd = require '../lib/mkcmd'
