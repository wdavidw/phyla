nikita = require 'nikita'
path = require 'path'

nikita
.log.cli()
.log.md basedir: path.join __dirname, "/.log"
.lxc.stop
  $header: 'Stop container: ryba-pg-test-1'
  container: 'ryba-pg-test-1'
.lxc.stop
  $header: 'Stop container: ryba-pg-test-2'
  container: 'ryba-pg-test-2'
