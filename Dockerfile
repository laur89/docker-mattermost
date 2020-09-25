FROM phusion/baseimage:master-amd64
MAINTAINER    Laur
# https://github.com/mattermost/mattermost-docker/
# https://docs.mattermost.com/install/prod-debian.html
# https://docs.mattermost.com/install/install-ubuntu-1604.html

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        curl \
        netcat \
        jq \
        unattended-upgrades && \
    update-locale LANG=C.UTF-8 && \
    curl https://releases.mattermost.com/5.27.0/mattermost-team-5.27.0-linux-amd64.tar.gz | tar -xvz && \
    mv /mattermost /opt/ && \
    rm /opt/mattermost/config/config.json && \
    ln -s /mattermost/config/config.json /opt/mattermost/config/config.json && \
    mkdir /etc/service/mattermost && \
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY config.template.json /

# Mattermost daemon
ADD mattermost.sh /etc/service/mattermost/run

ADD setup-mattermost.sh /usr/local/sbin/setup-mattermost
ADD apt-auto-upgrades /etc/apt/apt.conf.d/20auto-upgrades

# Baseimage init process
ENTRYPOINT ["/sbin/my_init"]

WORKDIR "/mattermost"
