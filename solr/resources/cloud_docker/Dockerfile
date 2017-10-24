# RUN HUE

FROM centos:6.6

Maintainer Lucas Bkian

# Yum #

RUN yum install -y wget tar python  krb5-libs krb5-workstation vim
RUN yum install -y libxslt-devel
RUN yum install -y mysql mysql-connector-java
RUN yum install -y snappy
RUN yum install -y python-devel
RUN yum install -y openssl-devel
RUN yum install -y libxslt-devel
RUN yum install -y cyrus-sasl-gssapi unzip

# Java #

WORKDIR /tmp
RUN curl -L -O -H "Cookie: oraclelicense=accept-securebackup-cookie" -k "http://download.oracle.com/otn-pub/java/jdk/8u101-b13/jdk-8u101-linux-x64.rpm"
RUN rpm -ivh jdk-8u101-linux-x64.rpm
ENV JAVA_HOME /usr/java/default

RUN curl  -k  -o solr.tar.gz  "{{options.source}}"
ENV JAVA_HOME /usr/java/default

RUN curl -L -O -H "Cookie: oraclelicense=accept-securebackup-cookie" -k "http://download.oracle.com/otn-pub/java/jce/8/jce_policy-8.zip"
RUN unzip jce_policy-8.zip
RUN cp UnlimitedJCEPolicyJDK8/US_export_policy.jar /usr/java/default/jre/lib/security/US_export_policy.jar
RUN cp UnlimitedJCEPolicyJDK8/local_policy.jar /usr/java/default/jre/lib/security/local_policy.jar

# Layout #

RUN mkdir -p {{options.user.home}}
#RUN groupadd {{options.hadoop_group.name}} -g {{options.hadoop_group.gid}}
RUN groupadd {{options.group.name}} -g {{options.user.gid}}
RUN useradd {{options.user.name}} -u {{options.user.uid}} -g {{options.group.gid}} -m -d {{options.user.home}}
#RUN usermod -a -G {{options.hadoop_group.name}},{{options.group.name}} {{options.user.name}}
RUN usermod -a -G {{options.group.name}} {{options.user.name}}

# Install #

RUN mkdir -p {{options.install_dir}}
RUN tar -C {{options.install_dir}} -xzf /tmp/solr.tar.gz --strip-components 1
RUN ln -s {{options.install_dir}} {{options.latest_dir}}
RUN mkdir -p {{options.conf_dir}}
RUN ln -s {{options.latest_dir}}/conf {{options.conf_dir}}
RUN rm -rf {{options.latest_dir}}/bin/solr.in.sh
RUN ln -s {{options.conf_dir}}/solr.in.sh  {{options.latest_dir}}/bin/solr.in.sh

RUN mkdir -p {{options.pid_dir}}
RUN chown {{options.user.name}}:{{options.group.name}} -R {{options.pid_dir}}
RUN mkdir -p {{options.log_dir}}
RUN chown {{options.user.name}}:{{options.group.name}} -R {{options.log_dir}}
RUN chown {{options.user.name}}:{{options.group.name}} -R {{options.user.home}}
RUN ln -s {{options.conf_dir}}/solr.xml {{options.user.home}}/solr.xml 


RUN chown {{options.user.name}}:{{options.group.name}} -R {{options.install_dir}}

COPY docker_entrypoint.sh /docker_entrypoint.sh
RUN chmod +x /docker_entrypoint.sh
RUN chown {{options.user.name}}:{{options.group.name}} /docker_entrypoint.sh

USER root
RUN rm -f /tmp/solr.tar.gz

RUN echo 'ZONE="Europe/Paris"'> /etc/sysconfig/clock
RUN ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime
RUN rm -f /jdk-8u101-linux-x64.rpm

USER {{options.user.name}}
WORKDIR {{options.user.home}}
ENV TERM=xterm-256color

CMD ["./docker_entrypoint.sh"]
