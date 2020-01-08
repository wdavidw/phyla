
# Crontab Install

    module.exports = header: 'Crontab', handler: ({options}) ->

## Deploy crontabs

      {purge} = options
      @each options.crontabs, ({options}, callback) ->
        user = options.key
        crontabs = options.value

### Eventually purge previous crontab

        @system.execute
          header: "Delete all existing crontabs for user #{user}"
          if: purge
          user: user
          cmd: "crontab -u #{user} -r"
          code: [0, 1]
        , (err, {stdout, stderr}) ->
          throw err if err and not /^no crontab for/.test stderr

### Apply crontabs

        for crontab in crontabs
          @cron.add
            cmd: crontab.cmd
            when: crontab.when
            user: user
        @next callback

## Dependencies

    each = require 'each'
    path = require 'path'
    string = require '@nikitajs/core/lib/misc/string'

## Notes

Purging before re applying the rules is an easy choice but parsing and deleting individual rules does not seem to be a better option.

## TODO

- Validate crontabs

## Resources

*   [How to create a cron job using Bash automatically without the interactive editor?](https://stackoverflow.com/questions/878600/how-to-create-a-cron-job-using-bash-automatically-without-the-interactive-editor)
