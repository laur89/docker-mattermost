FROM alpine:3
MAINTAINER    Laur

# majority config in this Dockerfile taken from https://github.com/mattermost/mattermost/blob/master/server/build/Dockerfile
# note the upstream Dockerfile used to be based off alpine, but was migrated to debian/ubuntu stack w/ https://github.com/mattermost/mattermost/commit/efed80a90c8c83ca115df3208059645a5a046e19
#
# see also:
#   https://github.com/mattermost/mattermost-docker/ - archived repo
#   https://docs.mattermost.com/install/prod-debian.html - link dead
#   https://docs.mattermost.com/install/install-ubuntu.html
#   https://github.com/mattermost/mattermost-docker-preview

ENV LANG=C.UTF-8 \
    MATTERMOST_VER=7.10.5

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
  wv \
  poppler-utils \
  tidyhtml \
# following packages are added extra by maintainer:
  jq \
  grep \
  bash && \
# Get Mattermost
    #mkdir -p /mattermost/data /mattermost/plugins /mattermost/client/plugins && \ <- handled by our setup script
    curl https://releases.mattermost.com/$MATTERMOST_VER/mattermost-team-$MATTERMOST_VER-linux-amd64.tar.gz | tar -xvz && \
    mv /mattermost /opt/ && \
    rm /opt/mattermost/config/config.json && \
    ln -s /mattermost/config/config.json /opt/mattermost/config/config.json && \
  rm -rf /tmp/* /var/cache/apk/*

COPY config.template.json  /
ADD setup-mattermost.sh entrypoint.sh mattermost.sh  /usr/local/sbin/

#Healthcheck to make sure container is ready
HEALTHCHECK --interval=30s --timeout=10s \
  CMD curl -f http://localhost:8065/api/v4/system/ping || exit 1

EXPOSE 8065 8067 8074 8075

# Configure entrypoint and command
ENTRYPOINT ["/usr/local/sbin/entrypoint.sh"]
WORKDIR /mattermost
CMD ["/usr/local/sbin/mattermost.sh"]
