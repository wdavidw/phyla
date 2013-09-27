
each = require 'each'
mecano = require 'mecano'

module.exports = []

module.exports.push (ctx, next) ->
  @name 'Profile'
  ok = 0
  ctx.config.profile ?= {}
  each(ctx.config.profile)
  .parallel(10)
  .on 'item', (filename, content, next) ->
    ctx.write
      destination: "/etc/profile.d/#{filename}"
      content: content
    , (err, written) ->
      ok++ if written
      next err
  .on 'both', (err) ->
    next err, if ok then ctx.OK else ctx.PASS
