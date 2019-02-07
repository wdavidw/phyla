
nikita = require 'nikita'

describe 'hdfs mkdir', ->

  it 'create a dir with default permission and ownership', (next) ->
    nikita require './config.coffee'
    .register 'hdfs_mkdir', require '../lib/hdfs_mkdir'
    .register 'kexecute', require '../lib/kexecute'
    .kexecute cmd: """
      dir='/user/@rybajs/metal/nikita'
      if hdfs dfs -test -d $dir; then hdfs dfs -rm -r -skipTrash $dir; fi
      """
    .hdfs_mkdir
      # stdout: process.stdout
      # stderr: process.stderr
      target: "/user/@rybajs/metal/nikita/a/dir"
    .kexecute cmd: """
      hdfs dfs -test -d /user/@rybajs/metal/nikita/a/dir
      hdfs dfs -stat '%g;%u;%n' /user/@rybajs/metal/nikita/a/dir
      hdfs dfs -ls /user/@rybajs/metal/nikita/a/ | grep /user/@rybajs/metal/nikita/a/dir | sed 's/\\(.*\\)   -.*/\\1/'
      """
    , (err, status, stdout) ->
      string.lines(stdout.trim()).should.eql [
        'ryba;ryba;dir'
        'drwxr-x---'
      ]
    .next next

  it 'detect status', (next) ->
    nikita require './config.coffee'
    .register 'hdfs_mkdir', require '../lib/hdfs_mkdir'
    .register 'kexecute', require '../lib/kexecute'
    .kexecute cmd: """
      dir='/user/@rybajs/metal/nikita'
      if hdfs dfs -test -d $dir; then hdfs dfs -rm -r -skipTrash $dir; fi
      """
    .hdfs_mkdir
      target: "/user/@rybajs/metal/nikita/dir"
    , (err, status) ->
      status.should.be.true() unless err
    .hdfs_mkdir
      target: "/user/@rybajs/metal/nikita/dir"
    , (err, status) ->
      status.should.be.false() unless err
    .next next

string = require '@nikitajs/core/lib/misc/string'
