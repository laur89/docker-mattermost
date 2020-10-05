FROM alpine:3.12
MAINTAINER    Laur

# majority config in this Dockerfile taken from https://github.com/mattermost/mattermost-server/blob/master/build/Dockerfile
# see also:
#   https://github.com/mattermost/mattermost-docker/
#   https://docs.mattermost.com/install/prod-debian.html
#   https://docs.mattermost.com/install/install-ubuntu-1604.html

ENV LANG=C.UTF-8

RUN apk add --no-cache \
  ca-certificates \
  curl \
  libc6-compat \
  libffi-dev \
  linux-headers \
  mailcap \
  netcat-openbsd \
  xmlsec-dev \
  tzdata \
# following packages are added extra by maintainer:
  jq \
  grep \
  bash && \
# Get Mattermost
    curl https://releases.mattermost.com/5.27.0/mattermost-team-5.27.0-linux-amd64.tar.gz | tar -xvz && \
    mv /mattermost /opt/ && \
    rm /opt/mattermost/config/config.json && \
    ln -s /mattermost/config/config.json /opt/mattermost/config/config.json && \
  rm -rf /tmp/*

COPY config.template.json /
ADD setup-mattermost.sh entrypoint.sh mattermost.sh  /usr/local/sbin/

#Healthcheck to make sure container is ready
HEALTHCHECK --interval=30s --timeout=10s \
  CMD curl -f http://localhost:8065/api/v4/system/ping || exit 1

EXPOSE 8065 8067 8074 8075

# Configure entrypoint and command
ENTRYPOINT ["/usr/local/sbin/entrypoint.sh"]
WORKDIR /mattermost
CMD ["/usr/local/sbin/mattermost.sh"]
