nikita = require 'nikita'
path = require 'path'

nikita
.log.cli()
.log.md basedir: path.join __dirname, "/.log"
.lxc.delete
  $header: 'Delete container: ryba-pg-test-1'
  container: 'ryba-pg-test-1'
.lxc.delete
  $header: 'Delete container: ryba-pg-test-2'
  container: 'ryba-pg-test-2'
.lxc.network.delete
  $header: 'Delete network: rybapgtestpub'
  network: 'rybapgtestpub'
.lxc.network.delete
  $header: 'Delete network: rybapgtestpriv'
  network: 'rybapgtestpriv'
