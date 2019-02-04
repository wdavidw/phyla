
# Hive & HCatalog Client

    module.exports = header: 'Hive Client Install', handler: ({options}) ->

## Register

      @registry.register 'hconfigure', '@rybajs/metal/lib/hconfigure'
      @registry.register 'hdp_select', '@rybajs/metal/lib/hdp_select'

## Identities

By default, the "hive" and "hive-hcatalog" packages create the following
entries:

```bash
cat /etc/passwd | grep hive
hive:x:493:493:Hive:/var/lib/hive:/sbin/nologin
cat /etc/group | grep hive
hive:x:493:
```

      @system.group header: 'Group', options.group
      @system.user header: 'User', options.user

## Service

The phoenix server jar is referenced inside the HIVE_AUX_JARS_PATH if phoenix
is installed on the host.

      @service
        name: 'phoenix'
        if: options.phoenix_enabled
      # migration: wdavidw 170908, attempt to simplify package installation
      @service 'hive'
      @hdp_select 'hive-webhcat' # Selecting "hive-client" throw "Invalid package" error
      # @service 'hive'
      # @service 'hive-webhcat' # Install hcat command
      # @hdp_select 'hive-webhcat'
      @service
        name: 'hive-hcatalog'

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

Enrich the "hive-env.sh" file with the value of the options
"opts" and "heapsize". Internally, the environmental variables 
"HADOOP_CLIENT_OPTS" and "HADOOP_HEAPSIZE" are enriched
and they only apply to the Hive client.

Using this functionnality, a user may for example raise the heap size of Hive
Client to 4Gb by either setting a "opts" value equal to "-Xmx4096m" or the
by setting a "heapsize" value equal to "4096".

      @file.render
        header: 'Hive Env'
        source: "#{__dirname}/../resources/hive-env.sh.j2"
        target: "#{options.conf_dir}/hive-env.sh"
        local: true
        context: options: options
        eof: true
        backup: true

## SSL

      # @java.keystore_add
      #   header: 'Client SSL'
      #   keystore: options.truststore_location
      #   storepass: options.truststore_password
      #   caname: "hive_root_ca"
      #   cacert: ssl.cacert
      #   local: true
