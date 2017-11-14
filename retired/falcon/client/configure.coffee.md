
# Falcon Client Configure

[Apache Falcon](http://falcon.apache.org) is a data processing and management solution for Hadoop designed
for data motion, coordination of data pipelines, lifecycle management, and data
discovery. Falcon enables end consumers to quickly onboard their data and its
associated processing and management tasks on Hadoop clusters.

    module.exports = (service) ->
      {options, deps} = service

## Identities

      # User
      options.user ?= deps.falcon_server.options[0].user
      # Group
      options.group ?= deps.falcon_server.options[0].group

## Kerberos

      # Kerberos Test Principal
      options.test_krb5_user ?= deps.test_user.options.krb5.user

## Environment

      # Layout
      options.conf_dir ?= '/etc/falcon/conf'
      # Misc
      options.hostname = service.node.hosname
