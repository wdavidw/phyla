
# Pig Install

Learn more about Pig optimization by reading ["Making Pig Fly"][fly].

    module.exports = header: 'Pig Install', handler: (options) ->

## Identities

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Install

The pig package is install.

      @service
        header: 'Service'
        name: 'pig'
      @service
        header: 'HCat'
        name: 'hive-hcatalog'#install only client jars needed to communicate with hcat
      options.log 'TODO: pig-client not registered in hdp-select'
      # pig-client not registered in hdp-select
      # need to see if hadoop-client will switch pig as well
      # @call once: true, 'ryba/lib/hdp_select'
      # @hdp_select
      #   name: 'pig-client'

## Configure

TODO: Generate the "pig.properties" file dynamically, be carefull, the HDP
companion file defines no properties while the YUM package does.

      @file.ini
        header: 'Properties'
        target: "#{options.conf_dir}/pig.properties"
        content: options.config
        separator: '='
        merge: true
        backup: true
      @file
        header: 'Env'
        source: "#{__dirname}/resources/pig-env.sh"
        target: "#{options.conf_dir}/pig-env.sh"
        local: true
        write: [
          match: /^JAVA_HOME=.*$/mg
          replace: "JAVA_HOME=#{options.java_home}"
        ]
        mode: 0o755
        backup: true

## Dependencies

    quote = require 'regexp-quote'

[fly]: http://chimera.labs.oreilly.com/books/1234000001811/ch08.html
