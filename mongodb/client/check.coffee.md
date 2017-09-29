
# MongoDB Server check

## Check

  TODO: Functionnal test

    module.exports =  header: 'MongoDB Client Check', handler: ->
      {mongodb, user} = @config.ryba
      @call once: true, 'ryba/mongodb/router/wait'
