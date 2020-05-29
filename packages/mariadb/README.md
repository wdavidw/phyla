
# MariaDB module for Ryba

## Description

This service has been created to simplify the installation of a MariaDB environment on a cluster. It is a module for [Masson](https://github.com/adaltas/node-masson). It provides two services: one for installing the database server, and another for installing the client tools.

Any communication is cyphered by SSL/TLS. High Availability (HA) is optionally supported on a two nodes cluster with master/slave replication.

## Running the tests

To set up the environment:
1. Run `lerna bootstrap && lerna link` from the Ryba project root
2. Run `cd packages/mariadb` to enter the root directory of Ryba's mariadb package
3. Run `npm install masson` to install Masson to the mariadb package of Ryba.

To launch configuration tests, run `npm test`.
To launch functional tests, run `npm run test_fn`.
Tests are using [Mocha](https://mochajs.org/) & [ShouldJS](https://shouldjs.github.io/).
