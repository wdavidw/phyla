
# MariaDB module for Ryba

## Description

This service has been created to simplify the installation of a MariaDB environment on a cluster. It is a module for [Masson](https://github.com/adaltas/node-masson). It provides two services: one for installing the database server, and another for installing the client tools.

Any communication is cyphered by SSL/TLS. High Availability (HA) is optionnaly supported on a two nodes cluster with master/slave replication.

## Running the test

As a NodeJS package, the tests can all be launched automatically by using the `npm test` command. It only requires Masson to run. Tests are using [Mocha](https://mochajs.org/) & [ShouldJS](https://shouldjs.github.io/).

Run the tests in this repo with Masson:

```
# Install masson via the node package manager
npm install masson
# Run the tests
npm test
```
