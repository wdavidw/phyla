
# Java Prepare

Download the Oracle JDK.

    module.exports =
      header: 'Java Prepare'
      ssh: false
      sudo: false
      handler: ({options}) ->
        conosle.log 'sudo': options.sudo
        return unless options.prepare
        for version, info of options.jdk.versions
          @file.cache
            sudo: false
            header: "Oracle JDK #{version}"
            source: info.jdk.source
            location: true
            cookies: ['oraclelicense=a']
            md5: info.jdk.md5
            sha256: info.jdk.sha256
          @file.cache
            header: "Oracle JCE #{version}"
            source: info.jce.source
            sudo: false
            location: true
            cookies: ['oraclelicense=a']
            md5: info.jce.md5
            sha256: info.jce.sha256

## Resources

*   [metalcated script](https://github.com/metalcated/Scripts/blob/master/install_java.sh)
