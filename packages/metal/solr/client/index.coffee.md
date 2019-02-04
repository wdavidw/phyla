
# Solr Client

This module provide solr client, to operate, manage and administrate solr instances,
which are not running on the client node. Indeed, adminstrations operations are generally
directly run from solr lives' instances' binaries.

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        # solr_cloud: '@rybajs/metal/solr/cloud'
        # solr_cloud_docker: '@rybajs/metal/solr/cloud_docker'
      configure:
        '@rybajs/metal/solr/client/configure'
      commands:
        'prepare':
          '@rybajs/metal/solr/client/prepare'
        'install':
          '@rybajs/metal/solr/client/install'
