FROM docker.io/ubuntu:14.10
MAINTAINER genggjh <david.geng@idevops.net>

ENV MESOS_VERSION 0.22.1
RUN apt-get update && apt-get install -y git build-essential openjdk-7-jdk python-dev python-boto libcurl4-nss-dev libsasl2-dev maven libapr1-dev libsvn-dev dh-autoreconf libz-dev autoconf libtool
#RUN apt-get install -y wget && wget -O /tmp/mesos-${MESOS_VERSION}.tar.gz http://www.apache.org/dist/mesos/0.22.1/mesos-${MESOS_VERSION}.tar.gz && \
#    cd /tmp && tar xzf mesos-${MESOS_VERSION}.tar.gz
RUN git clone https://git-wip-us.apache.org/repos/asf/mesos.git /tmp/mesos
WORKDIR /tmp/mesos
RUN git checkout tags/0.22.1 && ./bootstrap && mkdir build && cd build && ../configure && make
RUN apt-key adv --keyserver keyserver.ubuntu.com --recv E56151BF && \
    DISTRO=debian && \
    CODENAME=wheezy && \
    echo "deb http://repos.mesosphere.io/${DISTRO} ${CODENAME} main" | tee /etc/apt/sources.list.d/mesosphere.list && \
    DEBIAN_FRONTEND=noninteractive apt-get -y update && \
    apt-get -y install -yq --no-install-recommends marathon chronos unzip libsasl2-modules supervisor

RUN echo "deb http://archive-primary.cloudera.com/cdh5/debian/wheezy/amd64/cdh wheezy-cdh5 contrib" | tee /etc/apt/sources.list.d/cdh5.list && \
    echo "deb-src http://archive-primary.cloudera.com/cdh5/debian/wheezy/amd64/cdh wheezy-cdh5 contrib" >> /etc/apt/sources.list.d/cdh5.list && \
    curl -s http://archive.cloudera.com/cdh5/debian/wheezy/amd64/cdh/archive.key | apt-key add - && \
    apt-get -y update && \
    apt-get -y install hadoop-client

#Ignore /etc/hosts. Resolve this host via DNS
RUN sed 's/^\(hosts:[\ ]*\)\(files\)\ \(dns\)$/\1\3 \2/' -i /etc/nsswitch.conf

# Install consul
ENV DISABLE_CONSUL false
ENV CONSUL_VERSION 0.5.0
RUN apt-get update && apt-get install -y git unzip curl bash ca-certificates
ADD https://dl.bintray.com/mitchellh/consul/${CONSUL_VERSION}_linux_amd64.zip /tmp/consul.zip
RUN cd /bin && unzip /tmp/consul.zip && chmod +x /bin/consul && rm /tmp/consul.zip

ADD https://dl.bintray.com/mitchellh/consul/${CONSUL_VERSION}_web_ui.zip /tmp/webui.zip
RUN mkdir /ui && cd /ui && unzip /tmp/webui.zip && rm /tmp/webui.zip && mv dist/* . && rm -rf dist

#RUN apt-get install -y aptitude && aptitude remove -y libcurl4-nss-dev libsasl2-dev maven libapr1-dev libsvn-dev dh-autoreconf libz-dev autoconf libtool
RUN apt-get purge --auto-remove -y maven dh-autoreconf autoconf
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
RUN rm -rf /tmp/mesos/.git && rm -rf /tmp/mesos/build/3rdparty && rm -rf /root/.m2

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

