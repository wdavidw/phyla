
# Keycloak

    module.exports = ({deps, options, node})->

## Installation

      options.source ?= "https://downloads.jboss.org/keycloak/10.0.1/keycloak-10.0.1.zip"
      options.installation_dir ?= "/opt"
      options.admin_pw ?= "admin"

## SSL

      # options.ini['desktop']['ssl_certificate'] ?= path.join options.conf_dir , 'cert.pem'
      # options.ini['desktop']['ssl_private_key'] ?= path.join options.conf_dir , 'key.pem'
      # options.keystore ?= {}
      # options.keystore.password ?= "Ryba4Keycloak"

## Dependencies

    path = require 'path'
