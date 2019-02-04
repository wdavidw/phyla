
# MongoDB Server check

## Check

  TODO: Functionnal test

    module.exports =  header: 'MongoDB Client Check', handler: ->
      {mongodb, user} = @config.ryba
      @call once: true, '@rybajs/storage/mongodb/router/wait'
