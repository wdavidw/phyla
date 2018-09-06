
# Solr Install

    module.exports = header: 'Solr Client Install', handler: ({options}) ->
      tmp_archive_location = "/var/tmp/ryba/solr.tar.gz"

## Registry

      @registry.register ['file', 'jaas'], 'ryba/lib/file_jaas'

## Packages
Ryba support installing solr from apache official release or HDP Search repos.

      @call header: 'Packages', ->
        @call
          if:  options.source is 'HDP'
        , ->
          @service
            name: 'lucidworks-hdpsearch'
          @system.chown
            if: options.source is 'HDP'
            target: '/opt/lucidworks-hdpsearch'
            uid: options.user.name
            gid: options.group.name
        @call
          if: options.source isnt 'HDP'
        , ->
          @file.download
            source: options.source
            target: tmp_archive_location
          @system.mkdir
            target: options.install_dir
          @tools.extract
            source: tmp_archive_location
            target: options.install_dir
            preserve_owner: false
            strip: 1
          @system.link
            source: options.install_dir
            target: options.latest_dir

## Solr Client JAAS
      
      @file.jaas
        header: 'Solr JAAS'
        target: options.jaas_path
        content: Client:
          useTicketCache: 'true'
        mode: 0o644

## Zookeeper Scripts
Install the solr zkCli scripts to bottstrap and manage solr's zookeeper's nodes.

      @file.render
        header: 'ZkCli Script'
        source:"#{__dirname}/../resources/cloud_docker/zkCli.sh.j2"
        target: "#{options.latest_dir}/server/scripts/cloud-scripts/zkcli.sh"
        context: options
        local: true
        backup: true
        mode: 0o0751
