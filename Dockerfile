FROM yaronr/debian-jessie
MAINTAINER gengjh

# Setup
# Mesos fetcher uses unzip to extract staged zip files
# for lsb, see http://affy.blogspot.co.il/2014/11/is-using-lsbrelease-cs-good-idea-inside.html
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF && \
    DISTRO=debian && \
    CODENAME=wheezy && \
    echo "deb http://repos.mesosphere.io/${DISTRO} ${CODENAME} main" | tee /etc/apt/sources.list.d/mesosphere.list && \
    DEBIAN_FRONTEND=noninteractive apt-get -y update && \
    apt-get -y install -yq --no-install-recommends mesos marathon chronos unzip libsasl2-modules supervisor && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm /etc/mesos/zk && \
    rm /etc/mesos-master/quorum 

RUN echo "deb http://archive-primary.cloudera.com/cdh5/debian/wheezy/amd64/cdh wheezy-cdh5 contrib" | tee /etc/apt/sources.list.d/cdh5.list && \
    echo "deb-src http://archive-primary.cloudera.com/cdh5/debian/wheezy/amd64/cdh wheezy-cdh5 contrib" >> /etc/apt/sources.list.d/cdh5.list && \
    curl -s http://archive.cloudera.com/cdh5/debian/wheezy/amd64/cdh/archive.key | apt-key add - && \
    apt-get -y update && \
    apt-get -y install hadoop-client && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* 

#Ignore /etc/hosts. Resolve this host via DNS
RUN sed 's/^\(hosts:[\ ]*\)\(files\)\ \(dns\)$/\1\3 \2/' -i /etc/nsswitch.conf

# Install consul
ENV CONSUL_VERSION 0.5.0
RUN apt-get update && apt-get install -y git unzip curl bash ca-certificates
ADD https://dl.bintray.com/mitchellh/consul/${CONSUL_VERSION}_linux_amd64.zip /tmp/consul.zip
RUN cd /bin && unzip /tmp/consul.zip && chmod +x /bin/consul && rm /tmp/consul.zip

ADD https://dl.bintray.com/mitchellh/consul/${CONSUL_VERSION}_web_ui.zip /tmp/webui.zip
RUN mkdir /ui && cd /ui && unzip /tmp/webui.zip && rm /tmp/webui.zip && mv dist/* . && rm -rf dist

ADD entrypoint.sh /entrypoint.sh
ADD supervisord.d/mesos.conf /tmp/
ADD supervisord.d/consul.conf /tmp/
ADD supervisord.d/supervisord.conf /etc/supervisor/
RUN chmod a+x /entrypoint.sh

ADD ./consul/config/consul.json /tmp/consul.json

EXPOSE 8300 8301 8301/udp 8302 8302/udp 8400 8500 53 53/udp
VOLUME ["/data"]

ENV SHELL /bin/bash

ENTRYPOINT ["/entrypoint.sh"]

