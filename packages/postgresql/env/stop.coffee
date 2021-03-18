nikita = require 'nikita'

module.exports = ({params}) ->
  {config} = require params.clusterconf
  nikita
    $debug: params.debug
  .log.cli()
  .log.md basename: 'stop', basedir: params.logdir
  .lxc.cluster.stop {...config, wait: params.wait}
