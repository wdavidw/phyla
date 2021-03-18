nikita = require 'nikita'

module.exports = ({params}) ->
  {config} = require params.clusterconf
  nikita
    $debug: params.debug
  .log.cli()
  .log.md basename: 'start', basedir: params.logdir
  .lxc.cluster config
