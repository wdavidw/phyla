
# Phoenix QueryServer Check

    module.exports = header: 'Phoenix QueryServer Check', handler: ->

## Wait

      @call once: true, 'ryba/phoenix/queryserver/wait'
