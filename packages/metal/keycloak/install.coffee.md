
# Keycloak Install

## Metadata

    metadata =
      header: 'Keycloak Install'
  
## Install

    module.exports = header: metadata.header, handler: ({options}) ->

      @system.execute
        header: 'Install OpenJDK'
        unless_exec: 'java -version'
        cmd: """
        yum install -y java
        """

      @system.execute
        header: 'Install Keycloak'
        cmd: """
        yum install -y unzip
        curl https://downloads.jboss.org/keycloak/10.0.1/keycloak-10.0.1.zip -o /tmp/keycloak-10.0.1.zip
        unzip /tmp/keycloak-10.0.1.zip -d #{options.installation_dir}
        rm -rf /tmp/keycloak-10.0.1.zip
        """

## Configuration

### Admin user

      @system.execute
        header: 'Create admin user'
        cmd: """
        cd #{options.installation_dir}/keycloak-10.0.1
        bin/add-user-keycloak.sh -u admin -p #{options.admin_pw}
        """

### SSL

      @system.execute
        header: 'IPA certs symbolic links'
        unless_exec: 'ls /etc/x509/https/ | grep tls'
        cmd: """
        mkdir -p /etc/x509/https/
        ln -s /etc/ipa/cert.pem /etc/x509/https/tls.crt
        ln -s /etc/ipa/key.pem /etc/x509/https/tls.key
        """

      @system.execute
        header: 'Enable SSL via jboss cli'
        unless_exec: 'ls /opt/keycloak-10.0.1/standalone/configuration/keystores/ | grep https-keystore.jks'
        cmd: """
        export JBOSS_HOME="/opt/keycloak-10.0.1"
        /opt/keycloak-10.0.1/bin/x509.sh
        """

### Systemd Service

      @service.init
        header: 'Systemd Script'
        target: '/etc/systemd/system/keycloak.service'
        source: "#{__dirname}/assets/keycloak-systemd.j2"
        local: true
        uid: 'root'
        gid: 'root'
        mode: 0o0644

### SSSD/FreeIPA User Sync Provider

curl -L https://github.com/keycloak/libunix-dbus-java/releases/download/libunix-dbus-java-0.8.0/libunix-dbus-java-0.8.0-1.fc24.x86_64.rpm -o /tmp/libunix-dbus-java-0.8.0-1.fc24.x86_64.rpm
yum install -y /tmp/libunix-dbus-java-0.8.0-1.fc24.x86_64.rpm
yum install -y jna
yum install sssd-tools
sssctl user-checks admin -s keycloak

## Resources:   

* [Official Keycloak Getting Started](https://www.keycloak.org/getting-started/getting-started-zip)
* [SSSD and FreeIPA Identity Management Integration](https://www.keycloak.org/docs/latest/server_admin/#_sssd)