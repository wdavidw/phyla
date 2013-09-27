
###
Iptables
========
Administration tool for IPv4 packet filtering and NAT.
###
mecano = require 'mecano'
module.exports = []

###
Configuration
-------------
Configuration is declared through the key "iptables" and may contains the following properties:   

*   `startup`
    Start the service on system startup, default to "2,3,4,5".
*   `action`
    Action to apply to the service, default to "start".
###
module.exports.push (ctx) ->
  ctx.config.iptables ?= {}
  ctx.config.iptables.action ?= 'start'
  # Service supports chkconfig, but is not referenced in any runlevel
  ctx.config.iptables.startup ?= ''

###
Package
###
module.exports.push (ctx, next) ->
  @name 'Iptables # Package'
  @timeout -1
  {action, startup} = ctx.config.iptables
  ctx.service
    name: 'iptables'
    startup: startup
    action: action
  , (err, serviced) ->
    next err, if serviced then ctx.OK else ctx.PASS
