
# Hive Beeline Install

    module.exports = header: 'Hive Beeline Install', handler: ({options}) ->

## Register

      @registry.register 'hconfigure', '@rybajs/metal/lib/hconfigure'
      @registry.register 'hdp_select', '@rybajs/metal/lib/hdp_select'

## Service

      @service name: 'hive'
      @hdp_select 'hive-webhcat'

## Configure

See [Hive/HCatalog Configuration Files](http://docs.hortonworks.com/HDPDocuments/HDP1/HDP-1.3.2/bk_installing_manually_book/content/rpm-chap6-3.html)

      @hconfigure
        header: 'Hive Site'
        target: "#{options.conf_dir}/hive-site.xml"
        source: "#{__dirname}/../../resources/hive/hive-site.xml"
        local: true
        properties: options.hive_site
        merge: true
        backup: true
        mode: 0o644

## Env

      @file.render
        header: 'Hive Env'
        source: "#{__dirname}/../resources/hive-env.sh.j2"
        target: "#{options.conf_dir}/hive-env.sh"
        local: true
        context: options: options
        eof: true
        backup: true

## SSL

      @java.keystore_add
        header: 'Client SSL'
        keystore: options.truststore_location
        storepass: options.truststore_password
        caname: "hadoop_root_ca"
        cacert: "#{options.ssl.cacert.source}"
        local: "#{options.ssl.cacert.local}"

## Dependencies

    path = require 'path'
