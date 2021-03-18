nikita = require 'nikita'

module.exports = ({params}) ->
  {config} = require params.clusterconf
  nikita
    $debug: params.debug
  .log.cli()
  .log.md basename: 'delete', basedir: params.logdir
  .lxc.cluster.delete {...config, force: params.force}
