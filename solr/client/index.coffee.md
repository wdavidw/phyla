
# Solr Client

This module provide solr client, to operate, manage and administrate solr instances,
which are not running on the client node. Indeed, adminstrations operations are generally
directly run from solr lives' instances' binaries.

    module.exports =
      deps:
        krb5_client: module: 'masson/core/krb5_client', local: true, required: true
        java: module: 'masson/commons/java', local: true
        # solr_cloud: 'ryba/solr/cloud'
        # solr_cloud_docker: 'ryba/solr/cloud_docker'
      configure:
        'ryba/solr/client/configure'
      commands:
        'prepare':
          'ryba/solr/client/prepare'
        'install':
          'ryba/solr/client/install'
