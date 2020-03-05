
# Apt Packages Install

    module.exports = header: 'Apt', handler: ({options}) ->

### Install apt packages

      for pckg in options.packages
        @service
          header: "Install #{pckg} apt package"
          name: "#{pckg}"